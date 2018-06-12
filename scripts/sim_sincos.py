"""
Simulation
----------

This is a demo simulation expected to be run with Chronorama.
It describes two points oscillating.

The simulation runs in an infinite loop, use Ctrl-C to stop it.
"""

from math import cos, sin
from time import sleep

i = 0
while True:
    print(f"{(i - 100) * 5 % 200} {cos(i) * 20}", end=" ")
    print(f"{(i - 100) * 5 % 200} {sin(i) * 20}")

    # Slow down the simulation so we can visually grasp what is going on.
    sleep(1 / 30)

    i += 0.1
