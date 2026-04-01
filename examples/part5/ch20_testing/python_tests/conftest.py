# conftest.py — pytest configuration for python_tests/
#
# Adds the python_tests/ directory to sys.path so that ``import task_model``
# works regardless of where pytest is invoked from.

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
