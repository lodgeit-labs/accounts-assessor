#!/usr/bin/env python3


drate = 0.0595 / 365


opening = 75000
i1 = opening*61*drate
print(i1)
after_payment = opening - 10000# + i1
i2 = after_payment*304*drate
print(i2)

