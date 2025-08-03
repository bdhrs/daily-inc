## ItemType: Minutes 
### when start value is less than end value

how many days since last done?
if 0
    done today, nothing further to do
if 1
    increment today by increment value
if 2
    no increment or decrement
if 3 or more
    penalty decrement x (missed days -1)

increment and decrement are reversed for start value is greater than end value