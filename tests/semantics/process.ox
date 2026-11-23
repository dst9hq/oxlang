#!/usr/bin/env ox
val result = Process.run ["printf", "%s", "hello world"]
val _ = P.printf "%d: %s\n" result.status result.stdout
