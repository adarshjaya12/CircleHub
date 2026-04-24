#!/usr/bin/env python3
"""
Circle Hub — GPIO Bell Controller
Runs as a subprocess launched by the Flutter app (AlarmNotifier).
Communicates via stdin/stdout line protocol:

  RING  → start pulsing the solenoid at 10 Hz (50ms ON / 50ms OFF)
  STOP  → stop pulsing, ensure solenoid is de-energised
  QUIT  → clean up GPIO and exit

GPIO pin 17 (BCM) drives the solenoid via a relay or MOSFET driver.
The 12V solenoid must NOT be driven directly from the Pi GPIO (3.3V logic).
Use a logic-level MOSFET (e.g. IRLZ44N) with a flyback diode across the coil.

Wiring:
  Pi GPIO 17 → MOSFET gate (via 330Ω resistor)
  MOSFET drain → solenoid (-) terminal
  solenoid (+) terminal → 12V supply (+)
  12V supply (-) → MOSFET source → Pi GND
  1N4007 diode → across solenoid coil (cathode to 12V+)
"""

import sys
import threading
import time
import logging

logging.basicConfig(level=logging.INFO, format='[bell] %(message)s')
log = logging.getLogger(__name__)

BELL_PIN     = 17   # BCM pin number
PULSE_ON_S   = 0.05 # 50 ms ON
PULSE_OFF_S  = 0.05 # 50 ms OFF  →  10 Hz hammer rhythm

# ── GPIO init ─────────────────────────────────────────────────────────────

try:
    import RPi.GPIO as GPIO
    GPIO.setmode(GPIO.BCM)
    GPIO.setup(BELL_PIN, GPIO.OUT, initial=GPIO.LOW)
    GPIO_AVAILABLE = True
    log.info('GPIO initialised on BCM pin %d', BELL_PIN)
except (ImportError, RuntimeError) as e:
    GPIO_AVAILABLE = False
    log.warning('GPIO not available (%s) — running in simulation mode', e)

# ── State ──────────────────────────────────────────────────────────────────

_ringing   = threading.Event()
_exit_flag = threading.Event()

# ── Pulse loop (runs in dedicated thread) ─────────────────────────────────

def _pulse_loop():
    while not _exit_flag.is_set():
        if _ringing.is_set():
            if GPIO_AVAILABLE:
                GPIO.output(BELL_PIN, GPIO.HIGH)
            time.sleep(PULSE_ON_S)

            if GPIO_AVAILABLE:
                GPIO.output(BELL_PIN, GPIO.LOW)
            time.sleep(PULSE_OFF_S)
        else:
            # Idle — sleep cheaply
            time.sleep(0.05)

_pulse_thread = threading.Thread(target=_pulse_loop, daemon=True, name='bell-pulse')
_pulse_thread.start()

# ── Command reader (main thread) ────────────────────────────────────────────

log.info('Bell controller ready. Waiting for commands on stdin.')

try:
    for raw_line in sys.stdin:
        cmd = raw_line.strip().upper()
        if not cmd:
            continue

        if cmd == 'RING':
            log.info('RING command received — starting pulse')
            _ringing.set()

        elif cmd == 'STOP':
            log.info('STOP command received — stopping pulse')
            _ringing.clear()
            if GPIO_AVAILABLE:
                GPIO.output(BELL_PIN, GPIO.LOW)

        elif cmd == 'QUIT':
            log.info('QUIT command received — cleaning up')
            break

        else:
            log.warning('Unknown command: %r', cmd)

except (KeyboardInterrupt, EOFError):
    pass

finally:
    _exit_flag.set()
    _ringing.clear()
    if GPIO_AVAILABLE:
        GPIO.output(BELL_PIN, GPIO.LOW)
        GPIO.cleanup()
    log.info('Bell controller exited cleanly')
