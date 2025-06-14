# raccfmt

[![Gem Version](https://badge.fury.io/rb/raccfmt.svg)](https://badge.fury.io/rb/raccfmt)
[![Build Status](https://github.com/ydah/raccfmt/workflows/CI/badge.svg)](https://github.com/ydah/raccfmt/actions)

A configurable formatter for Racc grammar files. raccfmt helps you maintain consistent formatting in your `.y` files with customizable rules for indentation, spacing, alignment, and more.

## Features

- 🎨 **Configurable formatting rules** - Enable/disable individual rules via `.raccfmt.yml`
- 📏 **Smart indentation** - Automatic indentation for productions and actions
- 🔧 **Flexible spacing** - Control spacing around operators (`:`, `|`, `=`)
- 📐 **Alignment** - Align rule names, colons, and actions
- 📝 **Preserve comments** - Maintains your comments and documentation
- 🚀 **Fast** - Efficient parsing and formatting

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'raccfmt'
```

And then execute:

```bash
$ bundle install
```

Or install it yourself as:

```bash
$ gem install raccfmt
```

## Usage

### Basic Usage

Format a Racc grammar file and output to stdout:

```bash
$ raccfmt format grammar.y
```

Write the formatted output back to the file:

```bash
$ raccfmt format grammar.y --write
```

Check if a file needs formatting (useful for CI):

```bash
$ raccfmt format grammar.y --check
```

### Configuration

Generate a default configuration file:

```bash
$ raccfmt init
```

This creates a `.raccfmt.yml` file with all available options:

```yaml
---
rules:
  indent:
    enabled: true
    size: 2
    style: spaces  # or "tabs"
  brace_newline:
    enabled: true
    style: same_line  # or "new_line"
    space_before: true
  spacing:
    enabled: true
    around_colon: true
    around_pipe: true
    around_equals: true
  alignment:
    enabled: true
    align_actions: true
    align_rules: true
  empty_line:
    enabled: true
    between_rules: true
    after_header: true
    before_footer: true
```

### Examples

#### Before formatting:

```racc
program:stmt_list{result=val[0]}
stmt_list:stmt{result=[val[0]]}|stmt_list stmt{val[0]<<val[1]}
stmt:expr';'{result=val[0]}|'if'expr'then'stmt_list'end'{result=IfNode.new(val[1],val[3])}
```

#### After formatting:

```racc
program : stmt_list { result = val[0] }
        ;

stmt_list : stmt { result = [val[0]] }
          | stmt_list stmt { val[0] << val[1] }
          ;

stmt : expr ';' { result = val[0] }
     | 'if' expr 'then' stmt_list 'end' { result = IfNode.new(val[1], val[3]) }
     ;
```

## Formatting Rules

### Indent Rule

Controls indentation of productions and action blocks.

```yaml
indent:
  enabled: true
  size: 2        # Number of spaces/tabs
  style: spaces  # "spaces" or "tabs"
```

### Brace Newline Rule

Controls placement of action block braces.

```yaml
brace_newline:
  enabled: true
  style: same_line    # "same_line" or "new_line"
  space_before: true  # Add space before opening brace
```

**same_line style:**
```racc
rule : production { action }
```

**new_line style:**
```racc
rule : production
     {
       action
     }
```

### Spacing Rule

Controls spacing around operators.

```yaml
spacing:
  enabled: true
  around_colon: true   # "rule : prod" vs "rule:prod"
  around_pipe: true    # " | alt" vs "|alt"
  around_equals: true  # "a = b" vs "a=b"
```

### Alignment Rule

Aligns rule definitions and productions.

```yaml
alignment:
  enabled: true
  align_actions: true  # Align action blocks
  align_rules: true    # Align rule names and colons
```

**Example:**
```racc
program     : stmt_list
            ;

stmt_list   : stmt
            | stmt_list stmt
            ;

declaration : var_decl
            | func_decl
            ;
```

### Empty Line Rule

Controls empty lines between sections.

```yaml
empty_line:
  enabled: true
  between_rules: true    # Add empty lines between rules
  after_header: true     # Add empty line after header section
  before_footer: true    # Add empty line before footer section
```

## Command Line Options

### format command

```bash
$ raccfmt format [options] FILE
```

Options:
- `--config PATH` - Path to configuration file (default: `.raccfmt.yml`)
- `--write` - Write formatted output back to the file
- `--check` - Check if the file is formatted (exit 1 if not)

### init command

```bash
$ raccfmt init
```

Generates a default `.raccfmt.yml` configuration file.

### version command

```bash
$ raccfmt version
```

Shows the version of raccfmt.

## Integration

### Rake Task

Add to your `Rakefile`:

```ruby
desc "Format Racc grammar files"
task :format do
  sh "raccfmt format parser.y --write"
end

desc "Check Racc grammar formatting"
task :format_check do
  sh "raccfmt format parser.y --check"
end
```

### Pre-commit Hook

Create `.git/hooks/pre-commit`:

```bash
#!/bin/sh
files=$(git diff --cached --name-only --diff-filter=ACM | grep '\.y$')
if [ -n "$files" ]; then
  for file in $files; do
    raccfmt format "$file" --check || {
      echo "File $file is not formatted. Run 'raccfmt format $file --write' to fix."
      exit 1
    }
  done
fi
```

### GitHub Actions

```yaml
name: CI
on: [push, pull_request]

jobs:
  format:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.0'
      - run: gem install raccfmt
      - run: raccfmt format **/*.y --check
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt.

To install this gem onto your local machine, run `bundle exec rake install`.

### Running Tests

```bash
# Run all tests
bundle exec rake

# Run specific test file
bundle exec rspec spec/raccfmt/formatter_spec.rb

# Run with coverage
bundle exec rake coverage
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/yourusername/raccfmt. This project is intended to be a safe, welcoming space for collaboration.

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
