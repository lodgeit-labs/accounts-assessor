```
reset;echo -e "\e[3J";   swipl -O -s tests/pyco2_test2b.pl -g "test(q5(_,_)),halt" 2>&1 | tee logs/q5
```
