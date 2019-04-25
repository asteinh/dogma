classdef Settings < handle
  %SETTINGS A class for handling settings of objects.

  properties
    warnings = true; % Output warnings to command window
    mode = 'silent'; % Choose output level: silent, verbose
    graph = struct(); % Graph specific settings
    writer = struct(); % Writer specific settings
  end

  methods
    function obj = Settings()
      % Graph default settings
      obj.graph.filter = {'nodoc'}; % Files (match) that will be ignored; temporary files (ending with a tilde) are ignored automatically
      obj.graph.ignore = {'.', '..', '.DS_Store'}; % Files (exact match) that will be ignored
      
      %TODO implement
      obj.graph.ignoreSuperclass = {}; % Do not parse certain superclasses

      % Writer default settings
      obj.writer.author = [];
      obj.writer.title = [];

      obj.writer.ignoreSuperclass = {'handle', 'matlab.mixin.Copyable'}; % Do not generate output for certain superclasses
      obj.writer.filterHidden = true; % Hide properties/methods that have the attribute 'hidden' set
      obj.writer.filterPrivate = true; % Hide properties/methods that have the attribute 'GetAccess' set to 'private'

      obj.writer.HTML.baseURL = [];
      obj.writer.HTML.writeCode = false;

      obj.writer.LaTeX.standalone = true; % Generate standalone output or headerless content
      obj.writer.LaTeX.level_offset = 3; % Define a fixed offset that the LaTeX output starts from when sectioning output
      obj.writer.LaTeX.filename = 'main.tex'; % Define the file name for the output file
      obj.writer.LaTeX.generate_pdf = false; % Automatically generate PDF file once the LaTeX file is completely written

    end

    function setField(obj, key, val)
      obj.(key) = val;
    end
  end

end
