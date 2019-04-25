classdef ClassNode < dogma.graph.BaseNode
  %CLASSNODE

  properties
    is_in_class_folder = false;
  end

  methods
    function obj = ClassNode(parent, name, directory)
      obj@dogma.graph.BaseNode(parent, 'class', name, directory);

      % adapt for (classes in) class folders
      if obj.isClassFolder(directory)
        obj.type = dogma.graph.NodeType.ClassFolder;
        obj.setAttribute('type', obj.type);
        obj.setAttribute('name_matlab', [obj.getMatlabName(), '_cf']);
        % obj.node.removeChild(obj.node.getElementsByTagName('name_matlab').item(0));
      elseif obj.isClassFileInClassFolder(directory)
        obj.is_in_class_folder = true;
        obj.setAttribute('name_matlab', obj.parent.getMatlabName());
      end
    end

    function stats = index(obj, stats)
      if obj.type ~= dogma.graph.NodeType.ClassFolder
        error('Call to index() not allowed on class files!');
      end
      nDir = obj.getAttribute('directory');
      obj.notify(['Parsing ClassNode [', nDir, '] as ClassFolder']);

      % get content overview via 'help'
      cont = help(obj.getAttribute('name_matlab'));
      obj.addElement('short', []);
      obj.addElement('long', []);
      obj.addElement('content', strtrim(cont));

      stats = index@dogma.graph.BaseNode(obj, stats);
    end

    function parse(obj)
      %PARSE Parsing file if node is a class file.
      if obj.type ~= dogma.graph.NodeType.Class
        error('Call to parse() not allowed on classfolders!');
      end
      nDir = obj.getAttribute('directory');
      obj.notify(['Parsing ClassNode [', nDir, ']']);

      name_matlab = obj.getAttribute('name_matlab');

      % parsing a class file
      afp = dogma.parser.FileParser(nDir);

      % parse the classdef-line
      cdef = afp.parseClassDefinition();
      obj.addElement('classdef', cdef);

      % testing
      % cpro = afp.parseProperties();

      % get reference page via 'help' and remove title
      ccmt = help(name_matlab);
      [idxA,idxB] = regexp(ccmt, ['Reference page for ', name_matlab]);
      if ~isempty(idxA) && ~isempty(idxB)
        ccmt = ccmt([1:idxA-1, idxB+1:numel(ccmt)]);
      end

      [short, long] = obj.split_comment(ccmt);
      obj.addElement('short', short);
      obj.addElement('long', long);

      mc_info = eval(['? ' name_matlab]);

      % class info
      obj.setAttribute('hidden', num2str(mc_info.Hidden));
      obj.setAttribute('sealed', num2str(mc_info.Sealed));
      obj.setAttribute('abstract', num2str(mc_info.Abstract));
      obj.setAttribute('enumeration', num2str(mc_info.Enumeration));

      % get methods overview via 'methods'
      mets = mc_info.MethodList;

      % DEVELOP: instead of parsing plain text, utilize Matlab-builtins
      tree = mtree(strjoin(afp.getText(),'\n'));
      tree_functions = tree.Fname();
      tree_functions_idx = tree_functions.indices;

      for i = 1:1:numel(mets)

        % if ~any(strcmpi(mets(i).DefiningClass.Name, obj.settings.hideSuperclasses))
          method = obj.addElement('method', []);
          method.setAttribute('name', mets(i).Name);
          method.setAttribute('access', mets(i).Access);
          method.setAttribute('static', num2str(mets(i).Static));
          method.setAttribute('abstract', num2str(mets(i).Abstract));
          method.setAttribute('sealed', num2str(mets(i).Sealed));
          method.setAttribute('hidden', num2str(mets(i).Hidden));
          if strcmp(mets(i).DefiningClass.Name, name_matlab)
            method.setAttribute('defining_class', '');
            % TODO linenumbers only available for non-inherited methods atm
            linenum = NaN;
            [isFunction, fcnIndex] = ismember(mets(i).Name, strings(tree_functions), 'legacy');
            if isFunction
              nodeIndex = tree_functions_idx(fcnIndex);
              linenum = tree_functions.select(nodeIndex).lineno();
            end
            method.setAttribute('linenumber', num2str(linenum));
          else
            method.setAttribute('defining_class', mets(i).DefiningClass.Name);
          end
          h = help([name_matlab, '.', mets(i).Name]);
          [short, long] = obj.split_comment(h);

          method_interface = obj.doc.createElement('interface');
          method.appendChild(method_interface);
          for k = 1:1:numel(mets(i).InputNames)
            method_input = obj.doc.createElement('input');
            method_input.appendChild(obj.doc.createTextNode(mets(i).InputNames{k}));
            method_interface.appendChild(method_input);
          end
          for k = 1:1:numel(mets(i).OutputNames)
            method_output = obj.doc.createElement('output');
            method_output.appendChild(obj.doc.createTextNode(mets(i).OutputNames{k}));
            method_interface.appendChild(method_output);
          end

          method_short = obj.doc.createElement('short');
          method_short.appendChild(obj.doc.createTextNode(short));
          method.appendChild(method_short);
          method_long = obj.doc.createElement('long');
          method_long.appendChild(obj.doc.createTextNode(long));
          method.appendChild(method_long);
        % end
      end

      % write properties
      props = mc_info.PropertyList;
      for i = 1:1:numel(props)
        % if ~any(strcmpi(props(i).DefiningClass.Name, obj.settings.hideSuperclasses))
          property = obj.addElement('property', []);
          property.setAttribute('name', props(i).Name);
          property.setAttribute('getaccess', props(i).GetAccess);
          property.setAttribute('setaccess', props(i).SetAccess);
          property.setAttribute('constant', num2str(props(i).Constant));
          property.setAttribute('abstract', num2str(props(i).Abstract));
          property.setAttribute('hidden', num2str(props(i).Hidden));
          if strcmp(props(i).DefiningClass.Name, name_matlab)
            property.setAttribute('defining_class', '');
          else
            property.setAttribute('defining_class', props(i).DefiningClass.Name);
          end

          h = help([name_matlab, '.', props(i).Name]);
          [short, long] = obj.split_comment(h);
          short = strtrim(short(numel(props(i).Name)+5:end));
          property_short = obj.doc.createElement('short');
          property_short.appendChild(obj.doc.createTextNode(short));
          property.appendChild(property_short);
          property_long = obj.doc.createElement('long');
          property_long.appendChild(obj.doc.createTextNode(long));
          property.appendChild(property_long);
        % end
      end

      % write superclasses
      sups = mc_info.SuperclassList;
      for i = 1:1:numel(sups)
        superclass = obj.addElement('superclass', []);
        superclass.setAttribute('name', sups(i).Name);
      end
    end
  end

end
