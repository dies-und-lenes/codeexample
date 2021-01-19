Base.show(io::IO, node::TreeNode) = print(io, node.id)

function Base.show(io::IO, tree::Tree)
    println(io, "root: " * string(tree.root.id))
    println(io, "inner nodes:")
    println(io, "id <- parent")
    for node in tree.innernodes
        println(io, string(node[1]) * " <- " * string(node[2]))
    end
    println(io, "leaves:")
    println(io, "id <- parent")
    for node in tree.leaves
        println(io, string(node[1]) * " <- " * string(node[2]))
    end
    println(io, "leafmap:")
    println(io, "inner node -> leaves")
    for nd in tree.leavemap
        println(io, string(nd[1])* " -> " * string(nd[2]))
    end
end
