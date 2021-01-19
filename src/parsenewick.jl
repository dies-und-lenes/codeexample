

"""
    parsetree(str)

Return a tree object from a string that represents the tree in Newick format.

# Example:
```
parsetree("(A,B,(C,D)E);")
```
Note: this Newick parser is reduced
* no length information is considered
* empty leave signifiers are not allowed
It is based on the grammar formulated [here](https://en.wikipedia.org/wiki/Newick_format)
"""
function parsetree(str::AbstractString)
    root = getroot(str)
    tree = Tree(root,[],[], Dict())
    return match_subtree(chop(str), tree, root, Vector{TreeNode}()) #remove ; from tree
end

"""
    getroot(str)

Perfom the initial parsing step: check if the string ends with a ';' and create a root object.
"""
function getroot(str::AbstractString)
    if last(str) == ';'
        tree_block = match(r"\(?.*\)?([\w\._/]*):?[\w\._/]*", str)
        if isnothing(tree_block)
            error(str * " does not match")
        else
            root_name = tree_block.captures[1]
        end
        return Root(root_name)
    else
        error("last character of newick tree must be ';'")
    end
end

"""
Perform two alternative rules: either a subtree is a leaf or an internal node surrounded by parentheses and followed by an optional name"
"""
function match_subtree(str::AbstractString,
                       tree::Tree,
                       parent::TreeNode,
                       parents::Vector{TreeNode})
    if str == "" # TODO is this necessary
        return tree
    else
        internal = match(r"(\((?:.*,.*|(?R))*\)[\w\.:_/]*)", str)  #match(r"\(.*\)[\w:\.]*", str)
        leaf = match(r"([\w\._/]+):?[\w\._/]*", str)
        if !isnothing(internal)
            ##todo rootcase
            result = match_internal(internal.match, tree, parent, parents)
        elseif !isnothing(leaf)
            result = match_leaf(leaf.captures[1], tree, parent, parents)
        elseif isnothing(internal) && isnothing(leaf)
            error("couldnt match subtree in " * string(str))
        end
    end
    return result
end

"""
    match_internal(string, tree, parent, preds)

Matches an internal node, represented by a string surrounded by parentheses and followed by an optional name

# Example
* (A,B,(C,D)E) -> A,B,(C,D)E ~ node name is 'Nn', where n is a number
* (C,D)E -> C,D  ~  node name is 'E'
"""
function match_internal(str::AbstractString,
                        tree::Tree,
                        parent::TreeNode,
                        parents::Vector{TreeNode})

    internal = match(r"\((?:(.*,.*)|(?R))*\)([\w\._/]*):?[\w\._/]*", str)
    if internal.captures[2] == ""
        node = InnerNode("N" * string(length(tree.innernodes)))        
    else
        node = InnerNode(internal.captures[2])
    end
    push!(tree.innernodes, (node, parent))
    match_branch(internal.captures[1], tree, node, preds)
    return tree
end

"""
    match_branch(string, tree, parent, preds)

Realizes the grammar rule that accepts any sequence of commaseparated branches, where a branch is a leaf or an internal node
"""
function match_branch(str::AbstractString,
                      tree::Tree,
                      parent::TreeNode,
                      preds::Vector{TreeNode})
    for branch in split_branch(str)
        # prepare the leavemap for each inner node
        newpreds = Vector{TreeNode}()
        push!(newpreds, parent)
        match_subtree(branch, tree, parent, [newpreds;preds])
    end
end

"""
    split_branch(str)

Return a collection of branches, where each branch consists of either a leaf or an internal node.
Throws an error if the given string contains unbalanced parentheses

# Example
* 'A,B,(C,D)E' -> ['A','B','(C,D)E']
"""
function split_branch(str::AbstractString)
    branch_splits = Vector{Int64}()
    i = 0
    index = 0

    for s in str
        index+=1
        if s=='('
            i+=1
        elseif s== ')'
            i-=1
        elseif s == ',' && i == 0
            push!(branch_splits, index)
        end
    end

    if i != 0
        error("there are unbalanced parentheses!\n"*str)
    end

    branches = Vector{AbstractString}()
    if isempty(branch_splits)
        push!(branches, str)
        return branches
    end

    j=0
    for branch in branch_splits
        push!(branches, SubString(str, j+1, branch-1))
        j = branch
    end
    push!(branches, SubString(str, j+1, length(str)))
    return branches
end


"Check if a string matches the subtree pattern: comma separated leaf labels or internal nodes enclosed by balanced parentheses, optional label following a closing paren"
function is_subtree(str::AbstractString) #unused
    subtree = match(r"\((?:[^)(]*,[^)(]*|(?R))*\)[\w\.:_/]*", str)
    return subtree.match == str
end

"""
    add_leaf(string, tree, parent, preds)

Create a new entry in the leaf list of the tree and add the leaf to the leaflist of its predecessors.
"""
function add_leaf(str::AbstractString,
                    tree::Tree,
                    parent::TreeNode,
                    parents::Vector{TreeNode})
    
    push!(tree.leaves, (Leave(str), parent))
    add_parents(tree, Leave(str) , parents)
end

"""
    add_preds(tree, leaf, preds)

Replace the leaflist of all the inner nodes contained in `preds` by their leaflist that is extended by the `leaf`.
"""
function add_preds(tree::Tree, leaf::Leave, preds::Vector{TreeNode})
    for p in preds
        lm = get(tree.leavemap, p, [])
        push!(lm, leaf)
        push!(tree.leavemap, p=>lm)
    end
end


function parsetreeio(f::IOStream)
    return parsetree(read(f, String))
end




