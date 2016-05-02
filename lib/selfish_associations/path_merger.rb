module SelfishAssociations
  class PathMerger
    attr_reader :paths

    def initialize(paths)
      @paths = paths.select(&:present?)
    end

    # Take array of arrays in @paths and turn into a nested hash
    # Duplicate keys are collapsed into Array values
    # Endpoint values are guaranteed to be Arrays
    def merge
      merged_paths = @paths.reduce({}){|merged, path| merge_paths(merged, hashify_path(path))}
      return denillify(merged_paths)
    end

    # Convert each association index array into a 1-wide, n-deep Hash
    # For algorithmic convenience (see below), applies a nil endpoint
    # to all paths.
    # So
    #   [:a, :b, :c]
    # becomes
    #   {:a => {:b => {:c => nil}}}
    def hashify_path(path)
      path.reverse.reduce(nil){|path_partial, node| {node => path_partial}}
    end

    # Merge in a new hash path into the current merged hash paths.
    # Dup keys are combined as a merged Hash themselves: we need recursion!
    # Non-nil values are guaranteed to be Hashes because we've introduced the nil endpoint
    # Therefore we can simply merge all non-nil values recursivelye
    # So
    #   [[:a, :b, :c], [:a, :b], [:a, :x]
    # which hashifies into (remembering that we add nil endpoints)
    #   [{:a => {:b => {:c => nil}}}, {:a => {:b => :nil}}, {:a => {:x => nil}}]
    # now becomes
    #   {:a => {:b => {:c => nil}, {:x => nil}}}
    def merge_paths(paths, new_path)
      paths.merge!(new_path) do |parent_node, oldval, newval|
        if oldval.nil? || newval.nil?
          # If either old or new path ended at parent_node, use the other
          oldval || newval
        else
          # Else both paths continue from this node: recurse down the path!
          merge_paths(oldval, newval)
        end
      end
    end

    # Strip off the nil endpoints in a merged nillified Hash path Array.
    # 1-deep paths get un-Hashed. I.e., {key => nil} becomes just key.
    # >1-deep Hashes are guaranteed to have Hash values.
    # So, from above,
    #   {:a => {:b => {:c => nil}, {:x => nil}}}
    # now becomes
    #   {:a => [:x, {:b => :c}]}
    def denillify(paths)
      singles, hashes = paths.keys.partition{|k| paths[k].nil?}
      hashes.each{|k| paths[k] = denillify(paths[k])}
      return_array = singles
      return_array << paths.slice(*hashes) if hashes.present?
      return return_array.length == 1 ? return_array.first : return_array
    end

  end
end