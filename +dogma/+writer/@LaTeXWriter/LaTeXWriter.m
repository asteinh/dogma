classdef LaTeXWriter < dogma.writer.Writer
  %LATEXWRITER Writing a dogma XML tree to LaTeX output.
  % LaTeXWriter creates a single document (optionally standalone) containing
  % a table of contents and subsequently listing the nodes of the given tree.

  properties(Access = private)
    toc = [];
    relPath = struct( ...
      'styles', '+writer/@LaTeXWriter/styles/' ...
     );
    fid = [];
    levels = struct('name', { 'part', 'chapter', 'section', 'subsection', ...
                              'subsubsection', 'paragraph', 'subparagraph' });
    curr_level = 1;
  end

  methods
    function obj = LaTeXWriter(outputdir, dogma_)
      % Constructor
      obj@dogma.writer.Writer(outputdir, dogma_);
      obj.fid = fopen(fullfile(obj.paths.output_full, obj.settings.writer.LaTeX.filename), 'w');
    end

    function delete(obj)
      % Destructor
      obj.tryClose();
    end
  end

  methods(Access = protected)
    function init(obj)
      init@dogma.writer.Writer(obj);

      % set the current level for reference when writing content
      obj.curr_level = obj.curr_level + obj.settings.writer.LaTeX.level_offset;

      if obj.settings.writer.LaTeX.standalone
        % write LaTeX header if it's a standalone target
        txt = obj.latex_header();
        fprintf(obj.fid, '%s\n', txt{:});
        % copy default style 'hitec' to target directory
        [~, ~] = copyfile(fullfile(obj.paths.dogma, obj.relPath.styles, 'hitec.cls'), fullfile(obj.paths.output_full, 'hitec.cls'));
      else
        % create a sectioning containing all documentation
        txt = obj.latex_opening();
        fprintf(obj.fid, '%s\n', txt{:});
      end
    end

    function write(obj)
      %WRITE Method to navigate through the tree and call writing methods for
      %every node encountered.
      treewalker = obj.doc.createTreeWalker(obj.rootnode, 1, []);
      obj.write_dive(treewalker.getCurrentNode().getFirstChild());
    end

    function write_dive(obj, node)
      % Dive in
      if ~obj.doFilter(node)
        obj.writeNode(node);
        if node.hasChildNodes()
          obj.curr_level = obj.curr_level + 1;
          children = node.getChildNodes();
          for i = 0:1:(children.getLength()-1)
            if strcmp(char(children.item(i).getNodeName()), 'node')
              if strcmp(char(children.item(i).getAttribute('type')), 'ClassFolder')
                obj.curr_level = obj.curr_level - 1;
                obj.write_dive(children.item(i));
                obj.curr_level = obj.curr_level + 1;
              else
                obj.write_dive(children.item(i));
              end
            end
          end
          obj.curr_level = obj.curr_level - 1;
        end
      end
    end

    function finish(obj)
      finish@dogma.writer.Writer(obj);

      % write LaTeX footer if it's a standalone target
      if obj.settings.writer.LaTeX.standalone
        txt = obj.latex_footer();
        fprintf(obj.fid, '%s\n', txt{:});
      end

      obj.tryClose();

      if obj.settings.writer.LaTeX.standalone && obj.settings.writer.LaTeX.generate_pdf
        % trying a few pdf engines
        %TODO make this robust and platform-independent
        try
          [s, ~] = system(['pdflatex -halt-on-error -output-directory ', obj.paths.output_full, ' ', fullfile(obj.paths.output_full, obj.settings.writer.LaTeX.filename)]);
          if s
            [s, ~] = system(['latex2pdf -halt-on-error -output-directory ', obj.paths.output_full, ' ', fullfile(obj.paths.output_full, obj.settings.writer.LaTeX.filename)]);
            if s
              warning('Sorry, but we couldn''t find a PDF engine that is working here.');
            end
          end
        catch e
%           disp(e);
        end
      end
    end

    function writePackage(obj, node)
      % write basics
      [basics, fullname] = obj.generate_node_basics(node);
      fprintf(obj.fid, '%s\n', basics{:});

      % write content
      [packages, classes, enums, functions] = obj.scrobble_package(node);
      packages_list = obj.atomic_latex_packages_list(packages);
      fprintf(obj.fid, '%s\n', packages_list{:});
      classes_list = obj.atomic_latex_classes_list(classes);
      fprintf(obj.fid, '%s\n', classes_list{:});
      functions_list = obj.atomic_latex_functions_list(functions);
      fprintf(obj.fid, '%s\n', functions_list{:});
    end
    function writeClassFolder(obj, node)
      %TODO
    end
    function writeClass(obj, node)
      % write basics
      [basics, fullname] = obj.generate_node_basics(node);
      fprintf(obj.fid, '%s\n', basics{:});

      % get details of class
      [def, superclasses, props, methods] = obj.scrobble_class(node);
      def = strrep(def, '&', '\&');
      % write classdef line
      classdef_line = obj.atomic_latex_classdef(def);
      fprintf(obj.fid, '%s\n', classdef_line{:});

      % write
      superclasses_line = obj.atomic_latex_superclasses(superclasses);
      fprintf(obj.fid, '%s\n', superclasses_line{:});
      properties_overview = obj.atomic_latex_properties_overview(props);
      fprintf(obj.fid, '%s\n', properties_overview{:});
      functions_overview = obj.atomic_latex_functions_overview(methods);
      fprintf(obj.fid, '%s\n', functions_overview{:});
    end
    function writeFunction(obj, node)
      %TODO
    end
    function writeScript(obj, node)
      %TODO
    end
    function writeFolder(obj, node)
      %TODO
    end
    function writeOther(obj, node)
      %TODO
    end
  end

  methods(Access = private)
    function flag = tryClose(obj)
      try
        flag = fclose(obj.fid);
      catch
        flag = -1;
      end
    end
    function env = current_environment(obj)
      env = obj.levels(obj.curr_level).name;
    end
    function txt = latex_header(obj)
      txt = { ...
              '\documentclass[a4paper]{hitec}', ...
              '\usepackage{graphicx}', ...
              '\usepackage{xspace}', ...
              '\usepackage{hyperref}', ...
              '\usepackage{amsmath}', ...
              '\usepackage{amssymb}', ...
              '\usepackage[a4paper, bottom=30mm]{geometry}', ...
              '\settextfraction{.9}', ...
              '\setlength{\parindent}{0pt}', ...
              '\begin{document}', ...
              ['\title{', obj.title, '}'], ...
              ['\author{', obj.author, '}'], ...
              '\maketitle' ...
            };
    end
    function txt = latex_opening(obj)
      txt = { ['\', obj.current_environment(), '{', obj.title, '}'] };
      txt = [ txt, { [ '\textit{', obj.author, '}' ] } ];
      obj.curr_level = obj.curr_level + 1;
    end
    function txt = latex_footer(obj)
      txt = { '\end{document}' };
    end
    function [basics, name_matlab] = generate_node_basics(obj, node)
      name_matlab = char(node.getAttribute('name_matlab'));

      basics = { obj.atomic_latex_title(node) };
      basics = [ basics, { obj.atomic_latex_subtitle(node) } ];
      basics = [ basics, { obj.atomic_latex_short(node) } ];
      basics = [ basics, { obj.atomic_latex_long(node) } ];
    end
    function [def, superclasses, props, methods] = scrobble_class(obj, node)
      def = char(node.getElementsByTagName('classdef').item(0).getTextContent());
      superclasses = {};
      chnodes = node.getElementsByTagName('superclass');
      for i = 0:1:(chnodes.getLength-1)
        if chnodes.item(i).getParentNode.isSameNode(node)
          superclasses = [superclasses, { chnodes.item(i) } ];
        end
      end
      props = {};
      chnodes = node.getElementsByTagName('property');
      for i = 0:1:(chnodes.getLength-1)
        if chnodes.item(i).getParentNode.isSameNode(node) && ...
           ~obj.doFilter(chnodes.item(i)) && ...
           ~obj.doIgnore(chnodes.item(i))
          props = [props, { chnodes.item(i) } ];
        end
      end
      methods = {};
      chnodes = node.getElementsByTagName('method');
      for i = 0:1:(chnodes.getLength-1)
        if chnodes.item(i).getParentNode.isSameNode(node) && ...
           ~obj.doFilter(chnodes.item(i)) && ...
           ~obj.doIgnore(chnodes.item(i))
          methods = [methods, { chnodes.item(i) } ];
        end
      end
    end

    % Atomic helper functions
    function latex = atomic_latex_title(obj, node)
      latex = ['\', obj.current_environment(), '{', char(node.getAttribute('name')), '}'];
    end
    function latex = atomic_latex_subtitle(obj, node)
      latex = '\textbf{';
      if ~strcmp(char(node.getAttribute('type')), 'ClassFolder')
        latex = [latex, char(node.getAttribute('name_matlab'))];
      else
        latex = [latex, ['Class folder containing ', char(node.getAttribute('name')), ' class']];
      end
      latex = [latex, '}\\[1em]'];
    end
    function latex = atomic_latex_short(obj, node)
      nextshort = obj.getNextDirectChildByTag(node, 'short');
      if ~isempty(nextshort)
        latex = ['\textit{', char(nextshort.getTextContent()), '}\\[1em]'];
      else
        latex = '\textit{No direct child "short" found.}';
      end
    end
    function latex = atomic_latex_long(obj, node)
      nextlong = obj.getNextDirectChildByTag(node, 'long');
      if ~isempty(nextlong)
        latex = ['\textit{', char(nextlong.getTextContent()), '}\\[1em]'];
      else
        latex = '\textit{No direct child "long" found.}';
      end
    end
  end

  methods(Access = private, Static)
    function latex = atomic_latex_packages_list(packages)
      if numel(packages) > 0
        latex = { '\textbf{Packages}' };
        latex = [ latex, '\begin{itemize}' ];
        for i = 1:1:numel(packages)
          latex = [ latex, { [ '\item ', char(packages{i}.getAttribute('name')) ] } ];
        end
        latex = [ latex, { '\end{itemize}'} ];
      else
        latex = {};
      end
    end
    function latex = atomic_latex_classes_list(classes)
      if numel(classes) > 0
        latex = { '\textbf{Classes}' };
        latex = [ latex, '\begin{itemize}' ];
        for i = 1:1:numel(classes)
          latex = [ latex, { [ '\item ', char(classes{i}.getAttribute('name')) ] } ];
        end
        latex = [ latex, { '\end{itemize}'} ];
      else
        latex = {};
      end
    end
    function latex = atomic_latex_functions_list(functions)
      if numel(functions) > 0
        latex = { '\textbf{Functions}' };
        latex = [ latex, '\begin{itemize}' ];
        for i = 1:1:numel(functions)
          latex = [ latex, { ['\item ', char(functions{i}.getAttribute('name'))] } ];
        end
        latex = [ latex, { '\end{itemize}'} ];
      else
        latex = {};
      end
    end
    function latex = atomic_latex_classdef(def)
      latex = { ['\texttt{', char(def), '}\\' ] };
    end
    function latex = atomic_latex_superclasses(superclasses)
      if numel(superclasses) > 0
        latex = { '\textbf{Superclasses}' };
        latex = [ latex, '\begin{itemize}' ];
        for i = 1:1:numel(superclasses)
          latex = [ latex, { [ '\item ', char(superclasses{i}.getAttribute('name')) ] } ];
        end
        latex = [ latex, { '\end{itemize}'} ];
      else
        latex = {};
      end
    end
    function latex = atomic_latex_properties_overview(props)
      if numel(props) > 0
        latex = { '\textbf{Properties}' };
        latex = [ latex, '\begin{itemize}' ];
        for i = 1:1:numel(props)
          details = {};
          if strcmp(char(props{i}.getAttribute('abstract')), '1')
            details = [details, {'abstract'}];
          end
          if strcmp(char(props{i}.getAttribute('constant')), '1')
            details = [details, {'constant'}];
          end
          if strcmp(char(props{i}.getAttribute('hidden')), '1')
            details = [details, {'hidden'}];
          end
          details = strjoin(details, ', ');

          inherit = char(props{i}.getAttribute('defining_class'));
          if ~isempty(inherit)
            inherit = ['<span class="oi icon-inherited" data-glyph="action-redo" title="inherited from ', inherit,'" aria-hidden="true"></span>'];
          end

          %TODO what to do with short/long?
          % short = char(props{i}.getElementsByTagName('short').item(0).getTextContent());
          % long = char(props{i}.getElementsByTagName('long').item(0).getTextContent());
          latex = [ latex, { ['\item ', char(props{i}.getAttribute('name')) ] } ];
        end
        latex = [ latex, { '\end{itemize}'} ];
      else
        latex = {};
      end
    end
    function latex = atomic_latex_functions_overview(functions)
      if numel(functions) > 0
        latex = { '\textbf{Functions}' };
        latex = [ latex, '\begin{itemize}' ];
        for i = 1:1:numel(functions)
          inputs = functions{i}.getElementsByTagName('input');
          inputs_str = '';
          for k = 0:1:(inputs.getLength()-1)
            if k == 0
              inputs_str = char(inputs.item(k).getTextContent());
            else
              inputs_str = [inputs_str, ', ', char(inputs.item(k).getTextContent())];
            end
          end
          outputs = functions{i}.getElementsByTagName('output');
          outputs_str = '';
          for k = 0:1:(outputs.getLength()-1)
            if k == 0
              outputs_str = char(outputs.item(k).getTextContent());
            else
              outputs_str = [outputs_str, ', ', char(outputs.item(k).getTextContent())];
            end
          end
          if outputs.getLength() > 1
            outputs_str = ['[', outputs_str, ']'];
          end

          % inherit = char(functions{i}.getAttribute('defining_class'));
          % if ~isempty(inherit)
          %   inherit = ['<span class="oi icon-inherited" data-glyph="action-redo" title="inherited from ', inherit,'" aria-hidden="true"></span>'];
          % end
          %
          % short = char(functions{i}.getElementsByTagName('short').item(0).getTextContent());

          latex = [ latex, { ['\item ', char(functions{i}.getAttribute('name')) ] } ];
        end
        latex = [ latex, { '\end{itemize}'} ];
      else
        latex = {};
      end
    end
    function [packages, classes, enums, functions] = scrobble_package(node)
      packages = {};
      classes = {};
      enums = {};
      functions = {};
      chnodes = node.getElementsByTagName('node');
      for i = 0:1:(chnodes.getLength-1)
        if chnodes.item(i).getParentNode.isSameNode(node)
          if strcmpi(char(chnodes.item(i).getAttribute('type')), 'Package')
            packages = [packages, { chnodes.item(i) } ];
          elseif any(strcmpi(char(chnodes.item(i).getAttribute('type')), {'Class', 'ClassFolder'}))
            classes = [classes, { chnodes.item(i) } ];
          elseif strcmpi(char(chnodes.item(i).getAttribute('type')), 'Function')
            functions = [functions, { chnodes.item(i) } ];
          end
        end
      end
    end
    function res = getNextDirectChildByTag(node, tag)
      dchild = node.getElementsByTagName(tag).item(0);
      if dchild.getParentNode.isSameNode(node);
        res = dchild;
      else
        res = [];
      end
    end
  end
end
