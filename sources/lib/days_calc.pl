it's a fun mathematical quiz:

it starts with some constants:
  Days_1Y is 365,
  Days_4Y is (4 * Days_1Y) + 1,
  Days_100Y is (25 * Days_4Y) - 1,
  Days_400Y is (4 * Days_100Y) + 1,

which evaluate to:
  Days_1Y = 365,
  Days_4Y = 1461,
  Days_100Y = 36524,
  Days_400Y = 146097,

and then the formula is:
  Num_400Y is (Abs_Day - 1) div Days_400Y,
  Num_100Y is ((Abs_Day - 1) mod Days_400Y) div Days_100Y,
  Num_4Y is (((Abs_Day - 1) mod Days_400Y) mod Days_100Y) div Days_4Y,
  Num_1Y is ((((Abs_Day - 1) mod Days_400Y) mod Days_100Y) mod Days_4Y) div Days_1Y,
  Year_Day is 1 + (((((Abs_Day - 1) mod Days_400Y) mod Days_100Y) mod Days_4Y) mod Days_1Y),
  Year is 1 + (400 * Num_400Y) + (100 * Num_100Y) + (4 * Num_4Y) + (1 * Num_1Y)

now, for Abs_Day = 737791, these are probably correct results:
  Num_400Y = 5,
  Num_4Y = 5,
  Num_100Y = 0,
  Num_1Y = 0,
  Year_Day = 1, Year = 2021 .

and for Abs_Day = 737790, this is incorrect:
  Num_400Y = 5,
  Num_4Y = 4,
  Num_100Y = 0,
  Num_1Y = 4,
  Year_Day = 1, Year = 2021 ;

