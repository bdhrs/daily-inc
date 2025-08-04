## ItemType: Minutes 
### when start value is less than end value

how many days since last done?
if 0 (i.e. today)
    done today, nothing further to do
if 1 (i.e. yesterday)
    increment today by increment value
if 2 (i.e. the day before yesterday)
    no increment or decrement
if 3 or more (i.e. more than 2 days ago)
    penalty decrement x (missed days -1)

increment and decrement are reversed for start value is greater than end value