classdef FileParser < dogma.parser.Parser
  %FILEPARSER

  properties(Access = private)
    fid = 0;
    content = 0;
    pos = 1;
  end

  methods(Access = public)
    function obj = FileParser(file)
      % Constructor
      obj.fullpath = file;
      assert(exist(file, 'file') == 2, 'Could not find given filename.');
      obj.fid = fopen(file,'r');
      con = textscan(obj.fid, '%s', 'delimiter', '\n');
      obj.content = con{:};
      fclose(obj.fid);

      % TODO use mtree
      % obj.tree = mtree(obj.content);
    end

    function txt = getText(obj)
      txt = obj.content;
    end

    function cdef = parseClassDefinition(obj)
      %PARSECLASSDEFINITION Parse a classdef of a class file.

      % reset index to first line
      obj.pos = 1;
      while ~obj.isEOF()
        line = obj.getl();
        cdef = regexp(line, '(classdef .*)', 'tokens');
        if numel(cdef) ~= 0; break; end
      end
      if numel(cdef) == 0
        error('Couldn''t find a classdef!');
      elseif numel(cdef) == 1
        cdef = cdef{1}{1};  % return a string
      else
        error('Something went wrong when looking for a classdef!');
      end
    end

    function props = parseProperties(obj)
      %PARSEPROPERTIES Parse properties of a class file.

      % reset index to first line
      obj.pos = 1;

      props = struct('name', [], 'hidden', []);
      search_start = true;
      search_end = true;

      while ~obj.isEOF() && search_start
        line = obj.getl();
        match = regexp(line, '\t*properties.*', 'once');  % idx = number of leading spaces
        if numel(match) > 0
          % found a property block
          search_start = false;
          search_end = true;
          line_start = obj.pos-1;
          while search_end
            assert(~obj.isEOF(), 'Ran into end of class file before property block was closed.');
            line = obj.getl();
            match = regexp(line, '\t*end.*', 'once');  % idx = number of leading spaces
            if numel(match) > 0
              line_end = obj.pos-1;
              props(end+1) = obj.parsePropertyBlock(obj.content(line_start:line_end));
              search_end = false;
              search_start = true;
            end
          end
        end
      end
      props(1) = [];  % delete initial empty entry
    end

    function props = parsePropertyBlock(obj, block)

      props.name = 'a';
      props.attributes = obj.parseAttributes(block{1});
    end

    function attr = parseAttributes(obj, str)

    end

    function mets = parseMethods(obj)
      %PARSEMETHODS Parse methods of a class file.

      % limit search space to content after idx value
      obj.pos = idx;

      % TODO
      error('Not implemented.');

      mets = {};
    end
  end

  methods(Access = private)
    function block = parseCommentBlock(obj, idx)
      % limit search space to content after idx value
      obj.pos = idx;
      % parse whatever as long as not a comment line
      cline = [];
      while numel(cline) == 0
        cline = obj.parseCommentLine();
      end
      % parse as long as it is a comment line
      block = {};
      while numel(cline) >= 1
        block(end+1) = cline;
        cline = obj.parseCommentLine();
      end
    end
  end

  methods(Access = private, Hidden)
    function eof = isEOF(obj)
      eof = (obj.pos == numel(obj.content));
    end
    function line = getl(obj)
      assert(~obj.isEOF(), 'Cannot parse line: end of file reached.');
      line = obj.content{obj.pos};
      obj.pos = obj.pos + 1;
    end
    function skip_empty_lines(obj)
      line = obj.getl();
      idx = regexp(line, '\s*(.*)');
      while isempty(idx)
        line = obj.getl();
        idx = regexp(line, '\s*(.*)');
      end
    end
    function line = parseCommentLine(obj)
      line = obj.getl();
      line = regexp(line, '^\s*%+(.*)$', 'tokens');
      if numel(line) == 0
        line = {};
      elseif numel(line) == 1
        line = line{1};
      else
        error('Something went wrong parsing a comment line.');
      end
    end
  end

end
