"""Offline regressions: no probe/serial port is opened by these tests."""
import argparse
from contextlib import redirect_stdout, redirect_stderr
import io
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest
from unittest.mock import patch

TOOLS = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(TOOLS))
import dt
import uart_capture as uart


class DebugTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)

    def test_bin_requires_address_but_hex_retains_link_addresses(self):
        binary = self.root / 'image with spaces.bin'
        hexfile = self.root / 'app.hex'
        binary.touch()
        hexfile.touch()
        for backend in ('jlink', 'openocd'):
            with self.assertRaisesRegex(dt.DebugError, 'explicit address'):
                dt.image_args(binary, None, backend)
            with self.assertRaisesRegex(dt.DebugError, 'omit the address'):
                dt.image_args(hexfile, 0x08000000, backend)
            self.assertIn('0x08040000', dt.image_args(binary, 0x08040000, backend))
            self.assertNotIn('0x08000000', dt.image_args(hexfile, None, backend))
        self.assertIn('} 0x08040000 verify reset exit', dt.image_args(binary, 0x08040000, 'openocd'))

    def test_native_step_and_hold_do_not_add_interactive_input(self):
        commands = dt.jlink_commands('step')
        self.assertEqual(commands.count('s'), 1)
        self.assertNotIn('S', commands)
        self.assertNotIn('STM32F429IG', commands)
        self.assertIn('exec SetRestartOnClose = 0', commands)
        self.assertNotIn('g', dt.jlink_commands('flash', load='loadfile app.hex', hold=True))
        self.assertIn('g', dt.jlink_commands('flash', load='loadfile app.hex'))

    def test_commander_failure_after_successful_connection_is_not_success(self):
        good = 'Cortex-M4 identified.\nScript processing completed.'
        for text, code in ((good + '\nError: Cannot access memory', 0),
                           (good + '\nUnknown command. ?', 0), (good, 7), ('O.K.', 0)):
            with self.subTest(text=text, code=code), self.assertRaises(dt.DebugError):
                dt.check_jlink(dt.Result(code, text, self.root / 'log'))
        dt.check_jlink(dt.Result(0, good, self.root / 'log'))

    def test_gdb_expression_is_not_shell_text_and_halt_precedes_read(self):
        expressions = ['&Log_Tx_En', '((TCB_t*)user100msTask)->pcTaskName']
        commands = dt.gdb_commands('read', expressions, 3334, 'DONE')
        self.assertIn('target extended-remote localhost:3334', commands)
        self.assertLess(commands.index('monitor halt'), commands.index('p &Log_Tx_En'))
        self.assertIn('maintenance flush register-cache', commands)
        self.assertIn('p ' + expressions[1], commands)
        with self.assertRaises(dt.DebugError):
            dt.gdb_commands('read', ['x\nquit'], 3333, 'DONE')

    def test_gdb_zero_exit_cannot_hide_command_or_cleanup_failure(self):
        elf = self.root / 'app.elf'
        elf.touch()
        kit = dt.Toolkit({'DT_STATE_DIR': str(self.root / 'state'), 'DT_LOG_DIR': str(self.root)})
        args = dt.parser().parse_args(['read', '--reuse-server', '--backend', 'openocd', str(elf), 'counter'])

        def fake_run(argv, log, timeout, **kwargs):
            script = Path(argv[argv.index('-x') + 1]).read_text()
            cleanup = Path(argv[-1]).read_text()
            self.assertIn('localhost:3334', script)
            self.assertIn('monitor resume', cleanup)
            main_marker = script.splitlines()[-1][5:].replace('\\n', '')
            cleanup_marker = cleanup.splitlines()[-1][5:].replace('\\n', '')
            output = {'both': main_marker + '\n' + cleanup_marker,
                      'main': main_marker, 'cleanup': cleanup_marker}[mode]
            return dt.Result(0, output, log)

        with patch.object(dt, 'gdb_argv', return_value=['gdb.exe', '-nx']), patch.object(dt, 'run_program', side_effect=fake_run):
            for mode in ('main', 'cleanup'):
                with self.subTest(mode=mode), self.assertRaises(dt.DebugError):
                    kit.gdb(args)
            mode = 'both'
            self.assertEqual(kit.gdb(args), 0)

    def test_child_exit_and_output_preserved(self):
        result = dt.run_program([sys.executable, '-c', "print('tool error');raise SystemExit(7)"], self.root / 'child.log', 5)
        self.assertEqual(result.code, 7)
        self.assertIn('tool error', result.log.read_text())

    def test_timeout_is_nonzero_and_child_terminates(self):
        result = dt.run_program([sys.executable, '-c', 'import time; time.sleep(30)'], self.root / 'timeout.log', 0.1)
        self.assertEqual(result.code, 124)
        self.assertTrue(result.timed_out)

    @unittest.skipUnless(os.name == 'nt', 'Windows process identity')
    def test_stale_registry_cannot_kill_reused_or_unrelated_pid(self):
        process = subprocess.Popen([sys.executable, '-c', 'import time; time.sleep(30)'], creationflags=dt.HIDDEN)
        self.addCleanup(lambda: process.kill() if process.poll() is None else None)
        record = dt.process_identity(process.pid)
        dt.stop_process(dict(record, created=record['created'] + 1))
        self.assertIsNone(process.poll())
        dt.stop_process(dict(record, image='unrelated.exe'))
        self.assertIsNone(process.poll())
        dt.stop_process(record)
        self.assertEqual(process.wait(timeout=5), 0)

    def test_invalid_duration_and_port_fail(self):
        for value in ('0', '-1', 'nan', 'inf'):
            with self.subTest(value=value), self.assertRaises(argparse.ArgumentTypeError):
                dt.positive(value)
        with self.assertRaises(dt.DebugError):
            dt.main(['read', '--port', '70000', 'app.elf', 'x'])

    @unittest.skipUnless(os.name == 'nt', 'Windows entry and config')
    def test_direct_python_config_and_failure_exit(self):
        env = dict(os.environ, UART_PORT='COM88', UART_BAUD='57600',
                   JLINK_DIR=str(self.root / 'missing'))
        process = subprocess.run([sys.executable, '-B', str(TOOLS / 'dt.py'), 'read', 'missing.elf', 'counter'],
                                 cwd=self.root, env=env, capture_output=True, text=True)
        self.assertEqual(process.returncode, 1)
        self.assertIn('ELF not found', process.stderr)
        result = subprocess.run([sys.executable, '-B', str(TOOLS / 'dt.py'), 'uart', '--help'],
                                cwd=self.root, env=env, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0)
        self.assertIn('--baud', result.stdout)

    @unittest.skipUnless(os.name == 'nt', 'Windows portable configuration')
    def test_external_tool_overrides_are_replaced_before_launch(self):
        import json
        env = dict(os.environ)
        for key in (*dt.TOOL_DIRS, 'TOOLCHAIN_DIR'):
            env[key] = str(self.root / 'external install')
        code = 'import dt,os,json;dt.load_config();print(json.dumps({k:os.environ[k] for k in dt.TOOL_DIRS}))'
        result = subprocess.run([sys.executable, '-B', '-c', code], cwd=self.root,
                                env=env, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        for key, path in json.loads(result.stdout).items():
            self.assertEqual(Path(path).resolve(), (TOOLS / dt.TOOL_DIRS[key]).resolve())

    def test_missing_internal_tool_cannot_fall_back_to_external_executable(self):
        external = self.root / 'external'
        external.mkdir()
        (external / 'JLink.exe').touch()
        package = self.root / 'tools'
        package.mkdir()
        kit = dt.Toolkit({'JLINK_DIR': str(external), 'DT_STATE_DIR': str(self.root / 'state'),
                          'DT_LOG_DIR': str(self.root)})
        with patch.object(dt, 'ROOT', package):
            with self.assertRaisesRegex(dt.DebugError, 'missing bundled dependency'):
                kit.exe('JLINK_DIR', 'JLink.exe')
            with self.assertRaisesRegex(dt.DebugError, 'outside tools'):
                dt.bundled_path(external / 'JLink.exe')

    @unittest.skipUnless(os.name == 'nt', 'Bundled Windows GDB')
    def test_actual_gdb_resource_paths_are_internal_and_ignore_user_init(self):
        (self.root / '.gdbinit').write_text('echo EXTERNAL_INIT_LOADED\\n\n')
        commands = ['show data-directory', 'show debug-file-directory',
                    'show auto-load scripts-directory', 'show auto-load safe-path']
        argv = dt.gdb_argv() + ['-batch']
        for command in commands:
            argv += ['-ex', command]
        result = subprocess.run(argv, cwd=self.root, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stderr)
        output = result.stdout.replace('\\', '/').lower()
        self.assertNotIn('external_init_loaded', output)
        for line in output.splitlines():
            self.assertIn(TOOLS.as_posix().lower(), line)

    @unittest.skipUnless(os.name == 'nt', 'Bundled Windows OpenOCD')
    def test_openocd_imports_ignore_external_scripts_and_cwd(self):
        (self.root / 'mem_helper.tcl').write_text('error EXTERNAL_SCRIPT_LOADED\n')
        (self.root / 'external-only.tcl').write_text('error EXTERNAL_SCRIPT_LOADED\n')
        env = dict(os.environ, OPENOCD_SCRIPTS=str(self.root))
        kit = dt.Toolkit(dict(env, DT_STATE_DIR=str(self.root / 'state'), DT_LOG_DIR=str(self.root)))
        argv = kit.openocd_args()
        result = subprocess.run(argv + ['-c', 'echo PORTABLE_CONFIG_OK; shutdown'],
                                cwd=self.root, env=kit.env, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn('PORTABLE_CONFIG_OK', result.stdout + result.stderr)
        result = subprocess.run(argv + ['-c', 'find external-only.tcl; shutdown'],
                                cwd=self.root, env=kit.env, capture_output=True, text=True)
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('Missing bundled OpenOCD script', result.stdout + result.stderr)
        self.assertNotIn('EXTERNAL_SCRIPT_LOADED', result.stdout + result.stderr)
        kit.env['OPENOCD_TARGET'] = str(self.root / 'external-only.tcl')
        with self.assertRaisesRegex(dt.DebugError, 'outside tools'):
            kit.openocd_args()

    @unittest.skipUnless(os.name == 'nt', 'Windows byte range locking')
    def test_concurrent_lock_returns_clear_error_instead_of_permission_error(self):
        state = self.root / 'state'
        with dt.operation_lock(state):
            with self.assertRaisesRegex(dt.DebugError, 'another dt command'):
                with dt.operation_lock(state):
                    self.fail('lock admitted second owner')

    @unittest.skipUnless(os.name == 'nt', 'Windows server lifecycle')
    def test_fresh_server_stops_and_unregisters_after_client_exception(self):
        kit = dt.Toolkit({'DT_STATE_DIR': str(self.root / 'state'), 'DT_LOG_DIR': str(self.root)})
        kit.state.mkdir()
        with patch.object(kit, 'server_argv', return_value=[sys.executable, '-c', 'import time; time.sleep(30)']):
            with self.assertRaisesRegex(RuntimeError, 'client failed'):
                with kit.session_server('jlink', 0):
                    import json
                    record = json.loads((kit.state / 'server-jlink.json').read_text())
                    self.assertIsNotNone(dt.process_identity(record['pid']))
                    raise RuntimeError('client failed')
            self.assertFalse((kit.state / 'server-jlink.json').exists())
            self.assertIsNone(dt.process_identity(record['pid']))


class FakeSerial:
    def __init__(self, chunks):
        self.chunks = list(chunks)
        self.now = 0
        self.timeout = 0.1
        self.closed = False

    @property
    def in_waiting(self):
        return len(self.chunks[0]) if self.chunks else 0

    def read(self, length):
        self.now += 0.1
        return self.chunks.pop(0) if self.chunks else b''

    def __enter__(self):
        return self

    def __exit__(self, *_):
        self.closed = True


class UartTests(unittest.TestCase):
    def test_chunked_lines_overlapping_counts_and_log_content(self):
        ser = FakeSerial([b'Task1', b'00ms\r\nTask1000ms\n', b'Task100ms partial'])
        args = argparse.Namespace(count=['Task100', '^Task100ms$'], duration=0.5)
        log = io.StringIO()
        with redirect_stdout(io.StringIO()):
            result = uart.capture(ser, args, log, clock=lambda: ser.now)
        self.assertEqual(result['counts'], [2, 1])
        self.assertIn('Task100ms\n', log.getvalue())
        self.assertNotIn('Task1[', log.getvalue())
        self.assertIn('[partial; excluded from counts]', log.getvalue())
        self.assertIn('count[Task100] = 2', log.getvalue())

    def test_env_baud_and_port_are_used_and_resources_close(self):
        ser = FakeSerial([])
        with tempfile.TemporaryDirectory() as root:
            logfile = Path(root) / 'uart.log'
            with patch.dict(os.environ, UART_PORT='COM88', UART_BAUD='57600'), \
                    patch('serial.Serial', return_value=ser) as constructor, \
                    patch.object(uart, 'capture', return_value={}), redirect_stdout(io.StringIO()):
                self.assertEqual(uart.main(['--duration', '0.1', '--out', str(logfile)]), 0)
            constructor.assert_called_once_with('COM88', 57600, timeout=0.2)
            self.assertTrue(ser.closed)
            logfile.unlink()  # fails on Windows if the handle was leaked

    def test_invalid_regex_or_duration_never_opens_port(self):
        with patch('serial.Serial') as constructor, redirect_stderr(io.StringIO()):
            for argv in (['--count', '['], ['--duration', 'nan'], ['--duration', '0']):
                with self.subTest(argv=argv), self.assertRaises(SystemExit):
                    uart.main(argv)
            constructor.assert_not_called()

    def test_log_failure_closes_serial_and_returns_error(self):
        ser = FakeSerial([])
        with tempfile.TemporaryDirectory() as root, patch('serial.Serial', return_value=ser), redirect_stderr(io.StringIO()):
            self.assertEqual(uart.main(['--out', root, '--duration', '0.1']), 1)
            self.assertTrue(ser.closed)


if __name__ == '__main__':
    unittest.main()
