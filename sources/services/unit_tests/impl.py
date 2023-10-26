
# Generated by CodiumAI

import pytest

class TestGetYearDays:

    #  Returns 365 for a non-leap year.
    def test_returns_365_for_non_leap_year(self):
        assert get_year_days(2021) == 365

    #  Returns 366 for a leap year.
    def test_returns_366_for_leap_year(self):
        assert get_year_days(2020) == 366

    #  Returns an error if the input year is not an integer.
    def test_returns_error_for_non_integer_input(self):
        with pytest.raises(TypeError):
            get_year_days("2021")

    #  Returns an error if the input year is negative.
    def test_returns_error_for_negative_input(self):
        with pytest.raises(ValueError):
            get_year_days(-2021)

    #  Returns 365 for the year 1.
    def test_returns_365_for_year_1(self):
        assert get_year_days(1) == 365

    #  Returns 365 for the year 1582 (the year the Gregorian calendar was introduced).
    def test_returns_365_for_year_1582(self):
        assert get_year_days(1582) == 365

    #  Returns 366 for the year 2000 (a leap year).
    def test_returns_366_for_year_2000(self):
        assert get_year_days(2000) == 366