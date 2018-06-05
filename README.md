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
|  ├── js	               # theme javascript, Katex, jquery, bootstrap, jekyll search, 
|  ├── css                     # isolated Bootstrap, font-awesome, katex and main css
|  ├── fonts		       # Font-Awesome, Glyphicon, and other fonts
|  └── img		       # Images used for the template
├── pages
|   ├── 404.md		       # To be displayed when url is wrong
|   ├── about.md               # About example page
|   ├── search.html	       # Search page
|   └── search.json            # Specify the search target (page, post, collection)
├── _config.yml                # sample configuration
└── index.html                 # sample home page (blog page paginated)
```
	

## Usage

1. Fork and clone the [Unet blog repo](): `git clone git@github.com:org-arl/unet-blog.git`
2. Install [Jekyll](https://jekyllrb.com/docs/installation/): `gem install jekyll`, check [#1](/issues/1) if you have a problem.
3. Install the theme's dependencies: `bundle install`
4. Customize the theme
	- Github Page: [update `_config.yml`](#site-configuration)
5. Run the Jekyll server: `jekyll serve`


## Writing Blog Posts

### Create

### Drafts

### Layout

Please refer to the [Jekyll docs for writing posts](https://jekyllrb.com/docs/posts/). Non-standard features are documented below.

This are the basic features you can use with the  `post` layout.

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


### Math typesetting

When KateX is set in `_config.yml`:

```yml
  theme_settings:
     katex: true # to Enable it
```

You can then wrap math expressions with `$$` signs in your posts and make sure you have set the `katex` variable in `_config.yml` to `true` for math typesetting.

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
