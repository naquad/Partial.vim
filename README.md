# Partial

Partial is a plugin for running external command with given input and appending its output after selected/given range lines.

## Why?

Have you ever seen something like this:

```
#define XYZ1 0x10
#define XYZ2 0x20
#define XYZ3 0x30
#define XYZ4 0x40
#define XYZ5 0x50
#define XYZ6 0x60
#define XYZ7 0x70
#define XYZ8 0x80
#define XYZ9 0x90
#define XYZ10 0xA0
```

or

```
struct {
  char *data;
  size_t len;
} slen[] = {
  {
    .data = "string1",
    .len = 7
  },
  {
    .data = "string2",
    .len = 7
  },
  {
    .data = "string3",
    .len = 7
  },
  {
    .data = "string4",
    .len = 7
  },
  {
    .data = "string5",
    .len = 7
  },
};
```

When I type in some long/repeating static data I always think that it would be so awesome to quickly generate those with a script. I write a script and in an hour it figures out that I need to change something, I'm starting to look for that script or write it from scratch. Not very productive. Adding those as separate files quickly clobbers project directory with bunch of small generators, combining them is basically a separate project.

**Partial** tries to solve this problem by allowing you to inline your generator commands.

Examples above are actually look like theese **Partial** instructs:

```
/* #!ruby
 * 1.upto(10) do |n|
 *   puts "#define XYZ#{n} #{'0x%02X' % (n * 16)}"
 * end
 */
```

and

```
struct {
  char *data;
  size_t len;
} slen[] = {
  /* #!bash
   *
   * # bash here is solely for demonstration purpose
   *
   * for i in "string1" "string2" "string3" "string4" "string5"
   * do
   *   echo "{"
   *   echo " .data = \"$i\","
   *   echo " .len = ${#i}"
   *   echo "},"
   * done
   */
};
```

## What? 0_o

The general idea of this plugin is to execute given selection and insert its output after selection indenting it just like the first of line of selection.

This means that now you can have your code generation snippets right in your code w/o any special macro/syntax.

Just provide command and its input (optional). Thats it.

## How Does it Work

You select or provide a range with executable script. Command starts with a signature `#!` (by default, you can change this through `g:partial_command_signature` variable), and position of `#!` sets base offset. All following lines are copped until base offset and used as stdin for command. So:

```
some symbols like multiline comment start |#!some command
    this will be ignored                  |stdin starts here
           blah-blah-blah                 | another stdin line
  blah-blah-blah                          |     and one more
end of multiline comment
```

or

```
// #!awk '{print $1}'
// a b c d e
// x y z
// 1 2 3 4
```

**Partial** doesn't care about text before command signature.

Another example, HTML:

```
<ul>
<!--
    #!python
    for i in range(1, 10):
      print '<li>%d</li>' % i
-->
<li>1</li>
<li>2</li>
<li>3</li>
<li>4</li>
<li>5</li>
<li>6</li>
<li>7</li>
<li>8</li>
<li>9</li>
</ul>
```

Note that spaces before `#!` column were not included into stdin, everything before `#!` is trimmed.

Command can also span multiple lines, but should have additional padding = length of signature and line should end with `\` (potentially followed by spaces):

```
<!--
     #!ruby \
       -rubygems -rnokogiri -r
     # note extra spacing on next line
-->

```

Now to activate **Partial** you need to select text in visual mode and type `:Partial` or run it directly with line numbers like `:1,10Partial`.

If command exits with non-zero return code then it is considered to be failed and its output is not added, if you don't care about exit code then use `Partial!` instead of `Partial`. You will see stderr output anyway.

# Notes

One could say that **Partial** should know about comment syntax of specific file type and it would be more convenient probably, but if you'll look into some plugin like NERDCommenter you'll see that there's at least 340 known file types and their comments. And what about unknown types? Should you configure each and every file type that **Partial** is unaware about? What about plain text? Bottom line is indentation maybe less convenient and it can cause some head ache when one combines tabs and spaces, but usually that doesn't happen and it is a universal solution that doesn't depend on file type.

You can also execute one-liners:

```
// #!perl -e 'print "#define SIN$_ " . sin($_) . "\n" for 1..10'
```

input is optional.

Also note that command is executed as `(your command) >tmpfile 2>tmpfile <input`,
that is its not interactive, you can't call interactive commands.
