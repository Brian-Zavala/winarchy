"""Windows stand-ins for the two Unix-only calls in Omarchy's usage collectors.

The collectors in this folder are ports of Omarchy's bin/omarchy-agent-usage-*, kept as
close to upstream as possible so they can be re-synced. Everything in them is portable
standard library except two things, and this module is those two things:

  fcntl.flock(handle, LOCK_EX)   -> lock_exclusive(handle)
  select.select([pipe], ...)     -> LineReader(pipe).readline(timeout)

On Linux and macOS both fall straight through to the originals.
"""

from __future__ import annotations

import os
import queue
import threading
import time
from typing import IO, Optional

if os.name == "nt":
  import msvcrt

  def lock_exclusive(handle: IO) -> None:
    """Block until this process holds the lock file, like fcntl.flock(LOCK_EX).

    msvcrt locks a byte range rather than the whole file, and LK_LOCK gives up after
    ten one-second tries, so keep retrying: the collectors hold this lock only for the
    length of one transcript scan, and the caller is prepared to wait for it.
    """
    handle.seek(0)
    while True:
      try:
        msvcrt.locking(handle.fileno(), msvcrt.LK_LOCK, 1)
        return
      except OSError:
        time.sleep(0.1)

else:
  import fcntl

  def lock_exclusive(handle: IO) -> None:
    fcntl.flock(handle, fcntl.LOCK_EX)


class LineReader:
  """Read lines from a subprocess pipe with a timeout.

  Upstream polls the pipe with select.select(), which on Windows accepts sockets only
  and raises on a pipe. A daemon thread that does nothing but readline() into a queue
  gives the same "wait up to N seconds for the next line" behaviour everywhere; the
  thread ends by itself when the process closes its stdout.
  """

  _EOF = object()

  def __init__(self, stream: IO[str]) -> None:
    self._lines: "queue.Queue[object]" = queue.Queue()
    thread = threading.Thread(target=self._pump, args=(stream,), daemon=True)
    thread.start()

  def _pump(self, stream: IO[str]) -> None:
    try:
      for line in iter(stream.readline, ""):
        self._lines.put(line)
    except Exception:
      pass
    self._lines.put(self._EOF)

  def readline(self, timeout: float) -> Optional[str]:
    """The next line; "" once the stream has ended; None if nothing came in time."""
    try:
      item = self._lines.get(timeout=max(0.0, timeout))
    except queue.Empty:
      return None
    if item is self._EOF:
      # Leave the marker for any later caller, so EOF stays EOF.
      self._lines.put(self._EOF)
      return ""
    return item  # type: ignore[return-value]
