# Data Structures TODO

## Prerequisites (needed as underlying structures)
- [x] Dynamic Array
- [x] Ring Buffer

## Main Structures
- [x] Stack (using dynamic array)
- [x] Queue (doubly linked list)
- [x] Hash Map (array of linked list)
- [x] Deque (using doubly linked list)

## Potential improvements
- [ ] Merge Sort space complexity in linked lists (implement with pointer manipulation only)
- [ ] Ring buffer Push() method to not return overwritten value to make the API more intuitive
- [ ] Use std.meta.eql fir generic equality comparisons in data structures
- [ ] Make linked list iterators implementations more Zig idiomatic
- [ ] Custom error for better error handling when using the data structures

### Potential stuff i wanna add in the future
- Self-balancing (AVL rotations)
- Red-Black trees (color rules)
- Tree metrics (height, balance factor)
- Priority queues
- Heapsort
- n-ary tree
- Segment tree
- Tries (prefix tree or radix tree)
- Disjoint-set
- Graphs