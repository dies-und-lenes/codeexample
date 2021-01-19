abstract type TreeNode end

struct Root<:TreeNode
    id::String
end
struct InnerNode<:TreeNode
    id::String
end
struct Leave<:TreeNode
    id::String
end

"Returns true if the string is the same as the id of the node"
hasid(nd::TreeNode, id::AbstractString) = nd.id==id

"""
    Tree(root, innernodes, leaves, leavemap)

Tree structure modeling rooted trees. Consists of a root, a list of edges connecting inner nodes and a list of edges connecting the leaves of the tree with inner nodes. The leavemap maps an inner node to the set of leaves that are successors of the node.
"""
mutable struct Tree
    root::Root
    innernodes::Vector{Tuple{InnerNode, TreeNode}} # node, parent
    leaves::Vector{Tuple{Leave, TreeNode}}
    leavemap::Dict{TreeNode, Vector{Leave}}
end

function parent(tree::Tree, node::InnerNode)
    for n in tree.innernodes
        if n[1].id == node.id
            return n[2]
        end
    end
end
function parent(tree::Tree, node::Leave)
    for n in tree.leaves
        if n[1].id == node.id
            return n[2]
        end
    end
end

function get_leaves(tree::Tree, a::TreeNode)
    get(tree.leavemap, a, nothing)
end

function compute_leaves(tree::Tree)
    compute_leaves(tree, tree.root, Vector{TreeNode}())
end
function compute_leaves(tree::Tree, a::TreeNode, parents::Vector{TreeNode})
    if typeof(a)<:Leave
        for p in parents
            lm = get(tree.leavemap, p, Vector{Leave}())
            push!(lm, a)
            push!(tree.leavemap, p=>lm)
        end
        return
    end
    for v in [tree.innernodes ; tree.leaves]
        if a==v[2]
            compute_leaves(tree, v[1], [v[2];parents])
        end
    end    
end

function lca(tree::Tree, a::T,  b::T) where T<:Leave
    # colour all nodes of the tree black
    leaves = zip(map(x->x[1], tree.leaves), trues(length(tree.leaves)))
    innernodes = zip(map(x->x[1], tree.innernodes), trues(length(tree.innernodes)))
    blacknodes = merge(Dict(leaves), Dict(innernodes))
    # colour the path from a to root white
    while typeof(a) != Root
        push!(blacknodes, a=>false)
        a = parent(tree, a)
    end

    while get(blacknodes, b, false)
        b = parent(tree, b)
    end
    return b
end
