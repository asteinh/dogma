classdef FolderNode < dogma.graph.BaseNode
  %FOLDERNODE

  properties
  end

  methods
    function obj = FolderNode(parent, name, directory)
      obj@dogma.graph.BaseNode(parent, 'folder', name, directory);
    end

    function index(obj)
      error('Not implemented.');
    end
  end

end
