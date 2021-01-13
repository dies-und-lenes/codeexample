# Purpose 

This repo contains a small code example in Julia intended for playing around. It models a rooted tree, provides a parser for [Newick notation](https://en.wikipedia.org/wiki/Newick_format) and a function to compute the least common ancestor of two leaves.

# Instruction for use

In order to run the code example, navigate to the source folder and start julia: 

```
$ julia
```

Enter the following into the Julia prompt:

```
> include("Demo.jl")
```

Then you can parse a tree in Newick format, e.g.:

```
> parsetree("(A,B,(C,D));")
```
