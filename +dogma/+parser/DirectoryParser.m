classdef DirectoryParser < dogma.parser.Parser
  %DIRECTORYPARSER
  
  properties
    fid = 0;
  end

  methods
    function obj = DirectoryParser(directory)
      %DIRECTORYPARSER ...
      obj.fullpath = directory;
    end

    function txt = parseHelpSummaryFile(obj)
      %PARSEHELPSUMMARYFILE ...
      cFile = [obj.fullpath, '/Contents.m'];
      if exist(cFile, 'file') == 2
        fp = dogma.parser.FileParser(cFile);
        lines = {};
        while ~fp.isEOF()
          lines{end+1} = fp.parseLine();
        end
        txt = strjoin(lines, '\n');
      else
        txt = [];
      end
    end
  end

end
