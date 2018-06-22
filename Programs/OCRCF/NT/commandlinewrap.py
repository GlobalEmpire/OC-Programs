import sys

if __name__ == '__main__':
    optimise = None
    deleteinputs = False
    file = None
    for arg in sys.argv[1:]:
        try:
            code, val = arg.split("=")
            if code.lower() == '--opti':
                if val not in [1,2]:
                    print(f"Optimise Param not 1 or 2.")
                    sys.exit()
                else:
                    optimise = val
            elif code.lower == '--input':
                if 'y' in val.lower():
                    deleteinputs = True
            elif code.lower() == '--file':
                file = val

        except ValueError:
            print(f"Invalid Argument: {arg}")
            sys.exit()
