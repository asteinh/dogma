classdef OtherNode < dogma.graph.BaseNode
  %OTHERNODE

  properties
  end

  methods
    function obj = OtherNode(parent, name, directory)
      obj@dogma.graph.BaseNode(parent, 'other', name, directory);
    end

    function parse(obj)
      error('Not implemented.');
    end
  end

end
