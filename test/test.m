clear; clc;

addpath('../');
import dogma.*;

%% TARGET
m2d = dogma('+testpkg');
% m2d = dogma('../+dogma'); % I can index myself!

%% SETTINGS
m2d.set('mode', 'verbose');
m2d.set('warnings', false);

%% BUILD
m2d.buildTree();

%% EXPORT
% export DOM to xml
m2d.export('xml', './xmlout/test.xml');

% export DOM to LaTeX
m2d.settings.writer.author = 'test'; % set author
m2d.settings.writer.title = ['Documentation for ', m2d.pkg_name]; % set title
m2d.settings.writer.LaTeX.generate_pdf = true; % activate auto-generation of pdf output
m2d.export('latex', 'latexout');

% export DOM to HTML
m2d.settings.writer.HTML.baseURL = fullfile(pwd, '/htmlout/');
m2d.settings.writer.HTML.writeCode = true;
m2d.export('html', 'htmlout');
