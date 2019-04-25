classdef PackageNode < dogma.graph.BaseNode
  %PACKAGENODE

  properties
    % dp = [];
  end

  methods
    function obj = PackageNode(parent, name, directory)
      obj@dogma.graph.BaseNode(parent, 'package', name, directory);
    end

    function stats = index(obj, stats)
      nDir = obj.getAttribute('directory');
      obj.notify(['Parsing PackageNode [', nDir, ']']);

      % get content overview via 'help'
      cont = help(obj.getAttribute('name_matlab'));
      obj.addElement('short', []);
      obj.addElement('long', []);
      obj.addElement('content', strtrim(cont));

      stats = index@dogma.graph.BaseNode(obj, stats);
    end
  end

end
