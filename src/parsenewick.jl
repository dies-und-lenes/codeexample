################################################################################
# note: this newick parser is reduced
# - no length information is considered
# - empty leave signifiers are not allowed


function parsetree(str::AbstractString)
    root = getroot(str)
    tree = Tree(root,[],[], Dict())
    return match_subtree(chop(str), tree, root, Vector{TreeNode}()) #remove ; from tree
end

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
    match_branch(internal.captures[1], tree, node, parents)
    return tree
end

function match_branch(str::AbstractString,
                      tree::Tree,
                      parent::TreeNode,
                      parents::Vector{TreeNode})
    for branch in split_branch(str)
        # prepare the leavemap for each inner node
        newparents = Vector{TreeNode}()
        push!(newparents, parent)
        match_subtree(branch, tree, parent, [newparents;parents])
    end
end

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

function is_subtree(str::AbstractString)
    subtree = match(r"\((?:.*,.*|(?R))*\)[\w\.:_/]*", str)
    return subtree.match == str 
end

function match_leaf(str::AbstractString,
                    tree::Tree,
                    parent::TreeNode,
                    parents::Vector{TreeNode})
    
    push!(tree.leaves, (Leave(str), parent))
    add_parents(tree, Leave(str) , parents)
end

function add_parents(tree::Tree, node::Leave, parents::Vector{TreeNode})
    for p in parents
        lm = get(tree.leavemap, p, [])
        push!(lm, node)
        push!(tree.leavemap, p=>lm)
    end
end


function parsetreeio(f::IOStream)
    return parsetree(read(f, String))
end




