classdef dogma < dogma.graph.PackageNode
  %DOGMA Automated API documentation generation for Matlab packages.
  % dogma allows you to create an API documentation based on commented code in
  % your Matlab files. Automatically generate various output formats, such
  % as XML, HTML or LaTex.

  properties
    dogma_root = '';
    pkg_root = '';
    pkg_name = '';
    statistics = struct( ...
      'nodes', struct( ...
        'total', 0, ...
        'Package', 0, ...
        'ClassFolder', 0, ...
        'Class', 0, ...
        'Function', 0, ...
        'Script', 0, ...
        'Folder', 0, ...
        'Other', 0 ...
      ) ...
    );
  end

  methods
    function obj = dogma(pkg_path)
      %DOGMA Constructor for a dogma object.
      try
        baseDir = cd(pkg_path);
      catch e
        error('Could not change to given package directory!');
      end

      pkgDir = pwd;
      cd(baseDir);
      [~,idx] = regexp(pkgDir,'/');
      resStr = pkgDir(idx(end)+1:end);

      tokens = regexp(resStr, '\+?(.*)', 'tokens');
      assert(numel(tokens) == 1);
      name = tokens{1}{1};

      obj@dogma.graph.PackageNode([], name, pkgDir);

      obj.pkg_root = pkgDir(1:idx(end));

      filedir = mfilename('fullpath');
      [~,idx] = regexp(filedir,'/');
      obj.dogma_root = filedir(1:idx(end));

      obj.pkg_name = name;
    end

    function buildTree(obj)
      %BUILDTREE Iterates through this instance's package directory to
      %assemble a graph by creating nodes for every subpackage, class or
      %function found.

      tic;
%       if obj.settings.genpath_root
%         addpath(genpath(obj.pkg_root));
%       else
      oldpath = addpath(obj.pkg_root);
%       end
      obj.statistics.nodes = obj.index(obj.statistics.nodes);

%       if obj.settings.genpath_root
%         rmpath(genpath(obj.pkg_root));
%       else
      if numel(regexp(path, pathsep, 'split')) ~= numel(regexp(oldpath, pathsep, 'split'))
        rmpath(obj.pkg_root);
      end
%       end
      obj.statistics.timing = toc;

    end

    function export(obj, format, dest)
      if strcmpi(format, 'xml')
        xmlwrite(dest, obj.node);
      elseif strcmpi(format, 'html')
        w = dogma.writer.HTMLWriter(dest, obj);
        w.generate();
      elseif strcmpi(format, 'latex')
        w = dogma.writer.LaTeXWriter(dest, obj);
        w.generate();
      else
        error('Not yet implemented.');
      end
    end

    function nodes = getTree(obj)
      nodes = obj.getParentPointers(0);
    end

    function set(obj, key, val)
      obj.settings.setField(key, val);
    end
  end
end
