# Standard library
import time

# Local
from .utils import human_readable


class Progress:
    def __init__(self, total_records):
        self.time_start = time.monotonic()
        self.total_records = total_records

    def snapshot(self, iteration_number, total_iterations):
        """Get the current progress as a string"""
        f_complete = iteration_number / float(total_iterations)
        time_elapsed_total_ = time.monotonic() - self.time_start
        time_est_total_ = time_elapsed_total_ / f_complete
        percentage_ = 100.0 * f_complete
        completion_ = f"{human_readable(time_elapsed_total_)} of {human_readable(time_est_total_)}"
        rate_ = self.total_records * f_complete / time_elapsed_total_
        return f"{percentage_:>5.2f}% [{completion_}, {rate_:.2f} records/s]"
