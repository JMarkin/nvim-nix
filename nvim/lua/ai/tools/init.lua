return {
  calculator = {
    description = "Perform calculations",
    callback = {
      name = "calculator",
      cmds = {
        ---@param self CodeCompanion.Tool.Calculator The Calculator tool
        ---@param args table The arguments from the LLM's tool call
        ---@param input? any The output from the previous function call
        ---@return nil|{ status: "success"|"error", data: string }
        function(self, args, input)
          -- Get the numbers and operation requested by the LLM
          local num1 = tonumber(args.num1)
          local num2 = tonumber(args.num2)
          local operation = args.operation

          -- Validate input
          if not num1 then
            return { status = "error", data = "First number is missing or invalid" }
          end

          if not num2 then
            return { status = "error", data = "Second number is missing or invalid" }
          end

          if not operation then
            return { status = "error", data = "Operation is missing" }
          end

          -- Perform the calculation
          local result
          if operation == "add" then
            result = num1 + num2
          elseif operation == "subtract" then
            result = num1 - num2
          elseif operation == "multiply" then
            result = num1 * num2
          elseif operation == "divide" then
            if num2 == 0 then
              return { status = "error", data = "Cannot divide by zero" }
            end
            result = num1 / num2
          else
            return {
              status = "error",
              data = "Invalid operation: must be add, subtract, multiply, or divide",
            }
          end

          return { status = "success", data = result }
        end,
      },
      system_prompt = [[## Calculator Tool (`calculator`)

## CONTEXT
- You have access to a calculator tool running within CodeCompanion, in Neovim.
- You can use it to add, subtract, multiply or divide two numbers.

### OBJECTIVE
- Do a mathematical operation on two numbers when the user asks

### RESPONSE
- Always use the structure above for consistency.
]],

      schema = {
        type = "function",
        ["function"] = {
          name = "calculator",
          description = "Perform simple mathematical operations on a user's machine",
          parameters = {
            type = "object",
            properties = {
              num1 = {
                type = "integer",
                description = "The first number in the calculation",
              },
              num2 = {
                type = "integer",
                description = "The second number in the calculation",
              },
              operation = {
                type = "string",
                enum = { "add", "subtract", "multiply", "divide" },
                description = "The mathematical operation to perform on the two numbers",
              },
            },
            required = {
              "num1",
              "num2",
              "operation",
            },
            additionalProperties = false,
          },
        },
      },
      handlers = {
        ---@param self CodeCompanion.Tool.Calculator
        ---@param tools CodeCompanion.Tools The tool object
        setup = function(self, tools)
          return vim.notify("setup function called", vim.log.levels.INFO)
        end,
        ---@param self CodeCompanion.Tool.Calculator
        ---@param tools CodeCompanion.Tools
        on_exit = function(self, tools)
          return vim.notify("on_exit function called", vim.log.levels.INFO)
        end,
      },
      output = {
        ---@param self CodeCompanion.Tool.Calculator
        ---@param tools CodeCompanion.Tools
        ---@param cmd table The command that was executed
        ---@param stdout table
        success = function(self, tools, cmd, stdout)
          local chat = tools.chat
          return chat:add_tool_output(self, tostring(stdout[1]))
        end,
        ---@param self CodeCompanion.Tool.Calculator
        ---@param tools CodeCompanion.Tools
        ---@param cmd table
        ---@param stderr table The error output from the command
        error = function(self, tools, cmd, stderr)
          return vim.notify("An error occurred", vim.log.levels.ERROR)
        end,
      },
    },
  },
  ["cmd_runner"] = {
    callback = "ai.tools.cmd_runner",
    description = "Run shell commands initiated by the LLM",
  },
  ["next_edit_suggestion"] = {
    callback = "ai.tools.next_edit_suggestion",
    description = "Suggest and jump to the next position to edit",
  },
  ["insert_edit_into_file"] = {
    callback = "ai.tools.insert_edit_into_file",
    description = "Insert code into an existing file",
    opts = {
      patching_algorithm = "ai.tools.helpers.patch",
    },
  },
  ["create_file"] = {
    callback = "ai.tools.create_file",
    description = "Create a file in the current working directory",
  },
  ["fetch_webpage"] = {
    callback = "ai.tools.fetch_webpage",
    description = "Fetches content from a webpage",
    opts = {
      adapter = "jina",
    },
  },
  ["search_web"] = {
    callback = "ai.tools.search_web",
    description = "Searches the web for a given query",
    opts = {
      adapter = "tavily",
    },
  },
  ["file_search"] = {
    callback = "ai.tools.file_search",
    description = "Search for files in the current working directory by glob pattern",
    opts = {
      max_results = 500,
    },
  },
  ["grep_search"] = {
    callback = "ai.tools.grep_search",
    description = "Search for text in the current working directory",
  },
  ["read_file"] = {
    callback = "ai.tools.read_file",
    description = "Read a file in the current working directory",
  },
  ["list_code_usages"] = {
    callback = "ai.tools.list_code_usages",
    description = "Find code symbol context",
  },
  groups = {
    ["senior_dev"] = {
      description = "Tool Group",
      prompt = "I'm giving you access to ${tools} to help me out",
      tools = {
        "func",
        "cmd",
      },
    },

    ["tool_group"] = {
      description = "Tool Group",
      system_prompt = "My tool group system prompt",
      tools = {
        "func",
        "cmd",
      },
    },
    ["remove_group"] = {
      description = "Group to be removed during testing of context",
      system_prompt = "System prompt to be removed",
      tools = { "func", "weather" },
      opts = { collapse_tools = true },
    },
  },
  opts = {
    requires_approval = true,
    -- default_tools = {
    --   "cmd_runner",
    --   "grep_search",
    --   "read_file",
    --   "insert_edit_into_file",
    --   "create_file",
    --   "file_search",
    --   "next_edit_suggestion",
    -- },
    -- auto_submit_errors = true,
    -- auto_submit_success = true,
    folds = {
      enabled = true,
      failure_words = {
        "error",
        "failed",
        "invalid",
      },
    },
  },
}
