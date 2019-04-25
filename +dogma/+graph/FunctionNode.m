classdef FunctionNode < dogma.graph.BaseNode
  %FUNCTIONNODE
  
  properties
  end

  methods
    function obj = FunctionNode(parent, name, directory)
      obj@dogma.graph.BaseNode(parent, 'Function', name, directory);
    end

    function parse(obj)
      obj.notify(['Parsing FunctionNode [', obj.getAttribute('directory'), ']']);

      name_matlab = obj.getAttribute('name_matlab');
      ccmt = help(name_matlab);
      [short, long] = obj.split_comment(ccmt);

      obj.addElement('short', short);
      obj.addElement('long', long);
    end
  end

end
