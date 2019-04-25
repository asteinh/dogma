classdef Writer < handle
  %WRITER

  properties(Access = protected)
    paths = struct( ...
      'dogma', '', ...
      'output_full', '', ...
      'output_rel', '' ...
    );
    doc = [];
    settings = [];
    rootnode = [];
    pkg_name = '';
    statistics = [];

    author = [];
    title = [];

  end

  methods
    function obj = Writer(outputdir, dogma_)
      %WRITER Constructor of a Writer.

      % create destination folder
      obj.createFolder(outputdir);
      olddir = cd(outputdir);
      obj.paths.output_full = pwd();
      obj.paths.output_rel = outputdir;
      cd(olddir);

      obj.paths.dogma = dogma_.dogma_root;

      obj.doc = dogma_.doc;
      obj.settings = dogma_.settings;
      obj.rootnode = obj.doc.getElementsByTagName('dogma').item(0);
      obj.pkg_name = dogma_.pkg_name;
      obj.statistics = dogma_.statistics;
    end

    function generate(obj)
      %GENERATE Generate the output files.

      % splitting functionality for potential overloading by writer
      % implementations
      obj.init();
      obj.write();
      obj.finish();
    end
  end

  methods (Access = protected)
    function init(obj)
      %INIT Method to initialize the writing process.

      % set author
      if ~isempty(obj.settings.writer.author)
        obj.author = obj.settings.writer.author;
      else
        obj.author = 'dogma';
      end

      % set title
      if ~isempty(obj.settings.writer.title)
        obj.title = obj.settings.writer.title;
      else
        obj.title = obj.pkg_name;
      end
    end

    function write(obj)
      %WRITE Method to navigate through the tree and call writing methods for
      %every node encountered.

      % starting the big journey
      treewalker = obj.doc.createTreeWalker(obj.rootnode, 1, []);
      node = treewalker.nextNode;
      while ~isempty(node)
        obj.writeNode(node);
        node = treewalker.nextNode;
        while ~isempty(node) && ~strcmp(char(node.getNodeName),'node')
          node = treewalker.nextNode;
        end
      end
    end

    function finish(obj)
      %FINISH Method to finish the writing process.
      %TODO
    end

    function writeNode(obj, node)
      %WRITENODE Shorthand functionality to automate node-identication and calls
      %of the right writing methods.
      switch char(node.getAttribute('type'))
        case 'Package'
          obj.writePackage(node);
        case 'ClassFolder'
          obj.writeClassFolder(node);
        case 'Class'
          if ~obj.doFilter(node)
            obj.writeClass(node);
          end
        case 'Function'
          obj.writeFunction(node);
        case 'Script'
          obj.writeScript(node);
        case 'Folder'
          obj.writeFolder(node);
        case 'Other'
          obj.writeOther(node);
        otherwise
          error('Could not interpret NodeType.');
      end
    end
  end

  methods(Access = protected)
    function filter = doFilter(obj, node)
      filter = false;
      % filter hidden
      if (obj.settings.writer.filterHidden && strcmp(char(node.getAttribute('hidden')), '1')) || ...
         (obj.settings.writer.filterPrivate && strcmp(char(node.getAttribute('getaccess')), 'private')) || ...
         (obj.settings.writer.filterPrivate && strcmp(char(node.getAttribute('access')), 'private'))
        filter = true; return;
      end
    end
    function ignore = doIgnore(obj, node)
      ignore = false;
      % ignore superclass
      keys = obj.settings.writer.ignoreSuperclass;
      for i = 1:1:numel(keys)
        if strcmp(char(node.getAttribute('defining_class')), keys{i})
          ignore = true;
          break;
        end
      end
    end
  end

  methods (Access = protected, Abstract)
    % abstract methods for all NodeTypes
    writePackage(obj, node);
    writeClassFolder(obj, node);
    writeClass(obj, node);
    writeFunction(obj, node);
    writeScript(obj, node);
    writeFolder(obj, node);
    writeOther(obj, node);
  end

  methods (Static)
    function createFolder(folder)
      %TODO robustify
      [~,~,~] = mkdir(folder);
    end
  end

end
