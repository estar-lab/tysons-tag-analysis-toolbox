% factory that calls the constructors for all the other tags
% NO SUPPORT FOR MTAG
function tag = tag_importer(filename,tag_type,tag_name)
    switch tag_type
        case 'D4'
            fprintf("Importing " + tag_name + " as a D4\n");
            tag = D4(filename,tag_name);
            return;
        case 'D3'
            fprintf("Importing " + tag_name + " as a D3\n");
            tag = D3(filename,tag_name);
            return;
        case 'dataLogger'
            fprintf("Importing " + tag_name + " as a Data Logger\n");
            tag = dataLogger(filename,tag_name);
            return;
        case 'uTag'
            fprintf("Importing " + tag_name + " as an IMU Puck\n");
            tag = uTag(filename,tag_name);
            return;
        case 'sliced_tag'
            tag = standardTag(filename,tag_name);
            return;
        case 'mTag'
            fprintf("Importing " + tag_name + " as an MTAG\n");
            tag = mTag(filename,tag_name);
            return;
        case 'mTag2'
            fprintf("Importing " + tag_name + " as an MTAG2\n");
            tag = mTag2(filename,tag_name);
            return;
        otherwise
            fprintf(tag_type + " is not a valid tag type\n");
            return;
    end
end

