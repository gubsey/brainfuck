# brainfuck
My implementation of a brainfuck interpreter written in Zig.

-----

# The Why
I wanted to learn zig and needed a fun side project. Making an interpreter has been a long time goal of mine and I was never able to wrap my head around it.

# The How
The interpreter follows 3 simple steps.

1. Run the lexer
2. Define the bracket pairs
3. Run the code

Most implementations I've found have used a continuous section of memory for the "Tape" that the brainfuck code interacts with. I decided to go in a different direction. I have a ton of experience in functional languages, so it made more sense to me to do a doubly linked list. This proved fruitful as I had to learn a lot about the way zig allocates and preserves memory. In fact, the hardest part of writing this had nothing to do with brainfuck. Zig has very strange (to me) behavior around returning structs from functions. I figured that returning a struct without dropping it would preserve the contents of the struct, but that only happens when you allocate memory for it on the heap first. I still don't fully understand this and will need to do more research.
