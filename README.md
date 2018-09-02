# Unet Blog

## Table of Contents

1. [Usage](#Usage)
2. [Writing Blog Posts](#writing-blog-posts)
3. [Structure](#structure)
4. [License](#license)

## Structure

Here are the main files of the template

```bash
jekyll-theme-basically-basic
├── _draft	               # To store your drafts, they won't be published on your site
├── _includes	               # theme includes
├── _layouts                   # theme layouts (see below for details)
├── _posts                     # Blog posts
├── _sass                      # Sass partials 
├── assets
|  ├── js	                     # theme javascript, Katex, jquery, bootstrap, jekyll search, 
|  ├── css                     # isolated Bootstrap, font-awesome, katex and main css
|  ├── fonts		               # Font-Awesome, Glyphicon, and other fonts
|  └── img		       					 # Images used for the template
├── pages
|   ├── 404.md		             # To be displayed when url is wrong
|   ├── about.md               # About example page
|   ├── search.html	           # Search page
|   └── search.json            # Specify the search target (page, post, collection)
├── _config.yml                # sample configuration
└── index.html                 # sample home page (blog page paginated)
```
	

## Usage

1. Fork and clone the [Unet blog repo](): `git clone git@github.com:org-arl/unet-blog.git`
2. Install [Jekyll](https://jekyllrb.com/docs/installation/): `gem install jekyll`, check [#1](/issues/1) if you have a problem.
3. Install the theme's dependencies: `bundle install`
5. Run the Jekyll server: `jekyll serve --config _dev_config.yml`


## Writing Blog Posts

### Create

New posts can be created by adding a new markdown (`.md`) file to the [\_posts](_posts) directory. To create a post, add a file to your `\_posts` directory with the following format:

```
YEAR-MONTH-DAY-title.md 
```

Jekyll documentation explains [how to create a new post in much more detail](https://jekyllrb.com/docs/posts/#creating-posts). The [Layout](#layout) section has more information on how to add various types of content to your post.

When these files are commited to this repo `git commit` and the pushed to Github `git push`, the post will automatically get published on the blog.

### Drafts

Drafts are posts without a date in the filename. They're posts you're still working on and don't want to publish yet. Even if you commit these posts into this repo, they will not be publised to the blog. To create a draft, simply create a file in the `\_drafts` folder in your site’s root with the format `title.md`.

To preview your site with drafts, simply run `jekyll serve --drafts --config _dev_config.yml`. Each draft post will be assigned the value modification time of the draft file for its date, and thus you will see currently edited drafts as the latest posts.

### Layout

Please refer to the [Jekyll docs for writing posts](https://jekyllrb.com/docs/posts/). Non-standard features are documented below.

These are some basic features you can use with the  `post` layout.

```yml
---
layout: post
title: Hello World                                # Title of the page
feature-img: "assets/img/sample.png"              # Add a feature-image to the post
thumbnail: "assets/img/thumbnail/sample-th.png"   # Add a thumbnail image on blog view
tags: [sample, markdown, html]
---
```

### Post excerpt

The [excerpt](https://jekyllrb.com/docs/posts/#post-excerpts) are the first lines of an article that is display on the blog page. The length of the excerpt has a default of around `250` characters and can be manually set in the post using:
```yml
---
layout: post
title: Sample Page
excerpt_separator: <!--more-->
---

some text in the excerpt
<!--more-->
... rest of the text not shown in the excerpt ...
```

The html is stripped out of the excerpt so it only display text.

### Code and Syntax Highlighting

Github pages support syntax highlighting using [rouge](https://github.com/jneen/rouge). Adding source code to your post using the standard markdown fenced code blocks, will automatically render the block as sourcecode. 

For eg.

<pre>
```
  int getMTU() {
    return 32         // frame size
  }
```
</pre>

You can add an optional language identifier to enable syntax highlighting in your fenced code block.

For eg. following markdown will be rendered as : 

<pre>
```groovy
import org.arl.fjage.*
import org.arl.unet.*
``` 
</pre>

```groovy
import org.arl.fjage.*
import org.arl.unet.*
``` 


### Math typesetting

You can wrap math expressions with `$$` signs in your posts to have the corresponding latex expression to be rendered in the blog post.

For inline math typesetting, type your math expression on the *same line* as your content. For example:

```latex
Type math within a sentence $$2x^2 + x + c$$ to display inline
```

For display math typesetting, type your math expression on a *new line*. For example:

```latex
$$
  \bar{y} = {1 \over n} \sum_{i = 1}^{n}y_i
$$
```

### Tags

Tags should be placed between `[]` in your post metadata. Separate each tag with a comma. Tags are recommended for posts and portfolio items.

For example:

```yml
---
layout: post
title: Markdown and HTML
tags: [sample, markdown, html]
---
```

> Tags are case sensitive `Tag_nAme` ≠ `tag_name`

## License

[The MIT License (MIT)](https://raw.githubusercontent.com/Sylhare/Type-on-Strap/master/LICENSE)
