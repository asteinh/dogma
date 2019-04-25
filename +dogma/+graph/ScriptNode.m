classdef ScriptNode < dogma.graph.BaseNode
  %SCRIPTNODE

  properties
  end

  methods
    function obj = ScriptNode(parent, name, directory)
      obj@dogma.graph.BaseNode(parent, 'script', name, directory);
    end

    function parse(obj)
      obj.notify(['Parsing ScriptNode [', obj.getAttribute('directory'), ']']);

      %TODO
      obj.addElement('short', 'to be implemented...');
      obj.addElement('long', 'to be implemented...');
    end
  end

end
