# Standard library
import time

# Local
from .utils import human_readable


class Progress:
    def __init__(self, total_records=None):
        self.time_start = time.monotonic()
        self.processed_records = 0
        self.total_records = total_records

    def add(self, n_records):
        """Add a number of records to the progress counter"""
        self.processed_records += n_records
        self.processed_records = min(self.processed_records, self.total_records)

    @property
    def elapsed(self):
        """Amount of time that this progress tracker has been running"""
        return f"{human_readable(time.monotonic() - self.time_start)}"

    def __str__(self):
        """Get the current progress as a string"""
        f_complete = self.processed_records / float(self.total_records)
        time_elapsed_total_ = time.monotonic() - self.time_start
        time_est_total_ = time_elapsed_total_ / f_complete
        percentage_ = 100.0 * f_complete
        completion_ = f"{human_readable(time_elapsed_total_)} of {human_readable(time_est_total_)}"
        rate_ = self.total_records * f_complete / time_elapsed_total_
        return f"{percentage_:>6.2f}% [{completion_}, {rate_:.2f} records/s]"
