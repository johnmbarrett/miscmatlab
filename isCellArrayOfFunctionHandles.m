function fun = isCellArrayOfFunctionHandles() % for use in class definitions.  see https://www.mathworks.com/support/bugreports/1236377
    fun = @(x) iscell(x) && all(cellfun(@(y) isa(y,'function_handle'),x));
end