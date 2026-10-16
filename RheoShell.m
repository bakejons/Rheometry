%% rheometer client


while (1)
    % show list of functions
    args = input(string(datetime) + " AggieSurfaceScience " + "> ", "s");
    args = split(args, " ");
    buf = args{1};
    tag = [];
    if length(args) > 1
        tag = args{2};
    end

    switch buf
        case {"exit", "Exit", "kill"}
            exitfun()
            break

        case {"load", "Load"}
            filenames = getfiles();
            D = loadRheologyData(filenames);
            disp(D.info)

        case {"plot"}
            switch tag
                case "-v"
                    while (1)
                        t_in = input("Enter the data set to plot in order (Ex: 1, 2, 3:1:6, 10:-1:7): ", "s");
                        if t_in == ""
                            fprintf("Incorrect data ID try again\n")
                            continue
                        else
                            t_in = split(t_in, ",");
                            idx = [];
                            for i = 1:length(t_in)
                                idx = [idx,str2num(t_in{i})];
                            end
                            plotViscosity(D, idx);
                            fprintf("\n")
                            break
                        end
                    end
                otherwise
                    fprintf("Input a tag, -v, etc\n\n")
            end
        case {"help", "Help"}
            fprintf("List of Commands: \n")
            fprintf("   load: load in MCR 302e rheometer csv data for plotting \n")
            fprintf("   plot: plot data \n tags: -v viscosity vs shear rate\n")
            fprintf("   exit: terminate the shell\n")
            fprintf("   help: display this message\n\n")

        otherwise
            fprintf("Command unrecognized. Try again. Call help for a list of functions. \n\n")
    end
    prev_buf = tag;
    prev_tag = buf;
    buf = "";
end

function exitfun()
    fprintf("Exiting RheoShell! Goodbye!\n\n")    
    return
end