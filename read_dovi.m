function data = read_dovi(file_name, zrange)

% Copyright DoseOptics LLC 2017
%
% Reads DOVI data format into Matlab
% @param file_name - File name/location of DOVI file (e.g. 'test.dovi')
% @param zrange - [Optional] Range of slices to load (e.g. [1 40])
% @param data - Output data in Matlab


data = [];

% check inputs
if (length(file_name) < 5)
    return;
end
if (exist(fullfile(pwd, file_name), 'file'))
    file_name = fullfile(pwd, file_name);
end

% load header (dovi)
fs = fopen(file_name);
contents = textscan(fs,'%s');
fclose(fs);
x = 800;
y = 600;
z = 1;
compressed = 0;
cmp_size = 0;
ucmp_size = 0;
scalar_bytes = 2;
block = 0;
for i=1:length(contents{1})
    if (length(contents{1}{i}) > 5)
        if (contents{1}{i}(1:5) == 'dims0')
            x = str2num(contents{1}{i}(7:end));
        end
        if (contents{1}{i}(1:5) == 'dims1')
            y = str2num(contents{1}{i}(7:end));
        end
        if (contents{1}{i}(1:5) == 'dims2')
            z = str2num(contents{1}{i}(7:end));
        end
        if (contents{1}{i}(1:5) == 'block')
            block = str2num(contents{1}{i}(7:end));
        end
        if (length(contents{1}{i}) > 11)
            if (contents{1}{i}(1:11) == 'compressed=')
                compressed = str2num(contents{1}{i}(12));
            end
        end
        if (length(contents{1}{i}) > 15)
            if (contents{1}{i}(1:15) == 'compressed_size')
                cmp_size = str2num(contents{1}{i}(17:end));
            end
        end
        if (length(contents{1}{i}) > 17)
            if (contents{1}{i}(1:17) == 'uncompressed_size')
                ucmp_size = str2num(contents{1}{i}(19:end));
            end
        end
        if (length(contents{1}{i}) > 12)
            if (contents{1}{i}(1:12) == 'scalar_bytes')
                scalar_bytes = str2num(contents{1}{i}(14:end));
            end
        end
    end
end

fn_new = [file_name(1:end-5) '.raw'];
if (compressed)
    fn_new = [file_name(1:end-5) '.rawu'];
    if (~exist(fn_new, 'file'))
        % decompress
        disp('Uncompressing...');
        systemcall = ['"' which('uncompress_dovi.exe') '" "' file_name(1:end-5) '" ' ...
            num2str(block) ' ' num2str(x) ' ' num2str(y) ' ' num2str(z) ' ' ...
            num2str(scalar_bytes) ' ' num2str(cmp_size)];
        system(systemcall);
    end
end

if (nargin < 2)
    zrange = [1 z];
end

% load data
if (~exist(fn_new, 'file'))
    return;
end
fs = fopen(fn_new);
for i=1:zrange(1) - 1
    fread(fs, [x,y], 'uint16');
end
data = fread(fs, [x,y*(zrange(2) - zrange(1) + 1)], 'uint16');
fclose(fs);
data = uint16(reshape(data, x, y, zrange(2) - zrange(1) + 1));
data = permute(data, [2 1 3]);

% cleanup
% if (compressed)
%     delete(fn_new);
% end

