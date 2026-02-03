import os
from time import time


def fib():
    a, b = 0, 1
    while True:  # First iteration:
        yield a  # yield 0 to start with and then
        a, b = b, a + b  # a will now be 1, and b will also be 1, (0 + 1)


# Generate function where print first N of fibonachi numbers using fib function
def get_n_fibonacchi_numbers(n, messag_on_complete: str) -> list[int]:
