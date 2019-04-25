classdef BaseNode < handle
  %BASENODE Class for objects that represent nodes in a graph.

  properties (Constant)
    doc = com.mathworks.xml.XMLUtils.createDocument('dogma');
    settings = dogma.Settings();
  end

  properties (GetAccess = public, SetAccess = protected)
    node = [];
    parent = [];
    type = [];
  end

  methods
    function obj = BaseNode(parent, nodeType, filename, directory)
      %BASENODE Constructor of a BaseNode.

      obj.node = obj.doc.createElement('node');

      % handle parent
      if isempty(parent)
        obj.doc.insertBefore(obj.doc.createComment(datestr(now)), obj.doc.getDocumentElement);
        obj.parent = obj.doc.getDocumentElement;
        obj.parent.appendChild(obj.node);
      else
        obj.parent = parent;
        obj.parent.node.appendChild(obj.node);
      end

      % handle type
      obj.type = dogma.graph.NodeType.(nodeType);
      obj.setAttribute('type', obj.type);

      name = filename;
      if any(strcmp(name(1), {'@', '+'})); name = name(2:end); end
      obj.setAttribute('name', name);
      obj.setAttribute('name_file', filename);
      obj.setAttribute('name_matlab', obj.getMatlabName());
      obj.setAttribute('directory', directory);

    end

    function setAttribute(obj, attr, val)
      %SETATTR Set an attribute of an XML node to a certain value.
      newAttr = obj.doc.createAttribute(attr);
      newAttr.setValue(strtrim(char(val)));
      obj.node.setAttributeNode(newAttr);
    end

    function at = getAttribute(obj, attr)
      %GETATTR Get an attribute of an XML node.
      at = char(obj.node.getAttribute(attr));
    end

    function child = addElement(obj, tag, content)
      %ADDELEMENT Add an element to the node.
      child = obj.doc.createElement(tag);
      if ~isempty(content)
        child.appendChild(obj.doc.createTextNode(strtrim(char(content))));
      end
      obj.node.appendChild(child);
    end

    function addElementSep(obj, tag, content)
      %ADDELEMENTSEP Add an element with seperated entries to the node.
      assert(iscell(content) && numel(content) > 0);
      child = obj.doc.createElement(tag);
      for i = 1:1:numel(content)
        entry = obj.doc.createElement('entry');
        entry.appendChild(obj.doc.createTextNode(strtrim(char(content{i}))));
        child.appendChild(entry);
      end
      obj.node.appendChild(child);
    end

    function el = getElement(obj, tag)
      %GETELEMENT Get an element of the node.
      el = char(obj.node.getElementsByTagName(tag).item(0).getTextContent());
    end

    function setElement(obj, tag, content)
      %SETELEMENT Set an existing element's content of the node.
      obj.node.getElementsByTagName(tag).item(0).setTextContent(content);
    end

    function stats = index(obj, stats)
      %INDEX Indexes the subordinate elements of a node if this node is a
      %folder.

      nDir = obj.getAttribute('directory');

      if ~obj.isFolder(nDir); return; end

      %TODO use: what(nDir)

      elStruc = dir(nDir);
      elNames = {elStruc(:).name};
      elLocs = strcat([nDir, '/'], elNames);
      for i = 1:1:numel(elNames)
        name = elNames{i};
        loc = elLocs{i};
        if ~obj.doIgnore(name) && ~obj.isTempFile(name)
          if obj.isPackageFolder(loc)
            % PACKAGE FOLDER
            stats = dogma.graph.PackageNode(obj, name, loc).index(stats);
            stats.Package = stats.Package + 1;
          elseif obj.isClassFolder(loc)
            % CLASS FOLDER
            %TODO how to handle class folders (expecting the actual class
            %definition in a file contained in this folder)
            stats = dogma.graph.ClassNode(obj, name, loc).index(stats);
            stats.ClassFolder = stats.ClassFolder + 1;
          elseif obj.isFolder(loc)
            % GENERIC FOLDER
            %TODO what to do with other folders? insert something like a folder-node?
            stats = dogma.graph.FolderNode(obj, name, loc).index(stats);
            stats.Folder = stats.Folder + 1;
          elseif obj.isMFile(loc)
            % M FILE
            if obj.isClassFileInClassFolder(loc) || obj.isClassFile(loc)
              % CLASS
              dogma.graph.ClassNode(obj, obj.removeFileExtension(name), loc).parse();
              stats.Class = stats.Class + 1;
            elseif obj.isFunctionFile(loc)
              % FUNCTION
              dogma.graph.FunctionNode(obj, obj.removeFileExtension(name), loc).parse();
              stats.Function = stats.Function + 1;
            else
              % OTHER M-FILE
              obj.notify(['Other m-file found: ', loc]);
              dogma.graph.ScriptNode(obj, obj.removeFileExtension(name), loc).parse();
              stats.Other = stats.Other + 1;
            end
          else
            % NOT INTERPRETABLE
            % obj.warn(['Could not interpret the location ''', loc, '''.']);
            dogma.graph.OtherNode(obj, name, loc);
            stats.Other = stats.Other + 1;
          end
          stats.total = stats.total + 1;
        else
          if obj.isTempFile(name)
            obj.warn(['Ignoring temporary file ''', name, '''.']);
          else
            obj.warn(['Ignoring ''', name, ''' since you asked for it.']);
          end
        end
      end
    end
  end
  methods(Hidden = true)
    % helpers
    function fullname = getMatlabName(obj)
      thisName = obj.getAttribute('name');
      if obj.doc.getDocumentElement.isSameNode(obj.node.getParentNode)
        % most top level
        fullname = thisName;
      else
        % recursion
        fullname = [obj.parent.getMatlabName(), '.', thisName];
      end
    end

    function ign = doIgnore(obj, str)
      %DOIGNORE Finds out if a given file should be ignored based on the
      %given strings in the settings.
      filter = obj.settings.graph.filter;
      ignores = obj.settings.graph.ignore;
      ign = false;
      %TODO speedup with cellfun
      for i = 1:1:numel(filter)
        if strfind(str, filter{i})
          ign = true; return;
        end
      end
      for i = 1:1:numel(ignores)
        if strcmp(str, ignores{i})
          ign = true; return;
        end
      end
    end

    function notify(obj, msg)
      %NOTIFY Only print message if 'mode' is not set to 'silent'.
      if ~strcmp(obj.settings.mode,'silent')
        disp(msg);
      end
    end
    function warn(obj, msg)
      %WARN Only print warning if 'warnings' is set to true.
      if obj.settings.warnings
        warning(msg);
      end
    end
    function res = isPackageFolder(obj, entry)
      %ISPACKAGEFOLDER Returns true if the provided path 'entry' refers to
      %a package folder.
      res = obj.isFolder(entry) && (obj.strStartsWith(obj.strAfterDelim(entry,'/'), '+'));
    end
    function res = isClassFolder(obj, entry)
      %ISCLASSFOLDER Returns true if the provided path 'entry' refers to a
      %class folder.
      res = obj.isFolder(entry) && (obj.strStartsWith(obj.strAfterDelim(entry,'/'), '@'));
    end
    function res = isMFile(obj, entry)
      %ISMFILE Returns true if the provided path 'entry' refers to an
      %m-file.
      res = obj.isFile(entry) && (strcmp(obj.strAfterDelim(entry,'.'), 'm'));
    end
    function res = isTempFile(obj, name)
      %ISTEMPFILE Returns true if the provided name refers to a temporary
      %file.
      res = strcmp(name(end:end), '~');
    end
    function res = isClassFile(obj, entry)
      %ISCLASSFILE Returns true if the provided path 'entry' refers to a
      %file containting a class definition.
      txt = fileread(entry);
      %TODO robustify...
      res = numel(strfind(txt,'classdef')) > 0;
    end
    function res = isClassFileInClassFolder(obj, entry)
      %ISCLASSFILEINCLASSFOLDER Returns true if the provided path 'entry'
      %refers to a file containting a class definition of the parent class
      %folder.
      parts = strsplit(entry, '/');
      res = strcmp(parts{end-1}, ['@', obj.removeFileExtension(parts{end})]);
    end
    function res = isFunctionFile(obj, entry)
      %ISFUNCTIONFILE Returns true if the provided path 'entry' refers to a
      %file containting a function definition and no class definition.

      %TODO is that good enough?
      txt = fileread(entry);
      res = (numel(strfind(txt,'function')) >= 1) && ~obj.isClassFile(entry);
    end
    function res = isDir(obj)
      %ISDIR Returns true if the current object represents a directoryectory.
      res = obj.isFolder(obj.getAttribute('directory'));
    end
  end

  methods (Hidden, Static)
    function res = isFolder(entry)
      %ISFOLDER Returns true if the provided path 'entry' refers to a
      %folder.
      res = (exist(entry,'dir') == 7);
    end
    function res = isFile(entry)
      %ISFILE Returns true if the provided path 'entry' refers to a file.
      res = (exist(entry,'file') == 2);
    end
    function res = strStartsWith(str, key)
      %STRSTARTSWITH Returns true if the first characters of 'str' match
      %the provided 'key'.
      assert(ischar(str) && ischar(key), 'Search string and key must be strings.');
      res = strcmp(str(1:numel(key)),key);
    end
    function res = strAfterDelim(str, key)
      %STRAFTERDELIM Returns the string that is found in the 'searchStr'
      %after the last occurence of the given 'key'.
      if strcmp(key, '.')
        % special treatment when looking for a dot
        key = '\.';
        [~,idx] = regexp(str,key);
        key = '.';
      else
        [~,idx] = regexp(str,key);
      end
      if ~isempty(idx)
        res = str(idx(end)+numel(key):end);
      else
        res = [];
      end
    end
    function res = removeFileExtension(str)
      %REMOVEFILEEXTENSION Returns the string without a file extension.
      key = '\.';
      [~,idx] = regexp(str,key);
      if ~isempty(idx)
        res = str(1:idx(end)-1);
      else
        res = str;
      end
    end
    function name = strip_function_name(str)
      % input e.g. "obj BaseNode(parent, nodeType, name, directory)"
      % output: "BaseNode"

      % normally: between whitespace and opening bracket
      name = regexp(str, ' ?([^ ]+)\(','tokens');
      if numel(name) > 1
        error('Erm');
      elseif numel(name) == 1
        name = name{1}{1};
      else
        % next best guess: last word after a space
        rname = regexp(str, ' ([^ ]+)','tokens');
        name = rname{1}{1};
      end
    end
    function [short, long] = split_comment(comment)
      % splitting comment block into a short (H1) and long (rest) part
      parts = regexp(comment, '.*','match','dotexceptnewline');
      if numel(parts) > 0; short = strtrim(parts{1});
      else short = {}; end
      if numel(parts) > 1; long = strjoin(strtrim(parts(2:end)), ' ');
      else long = {}; end
    end
  end

end
