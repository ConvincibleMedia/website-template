---
features:
   -  "form"
layout: html/article
---

Sint ea anim ipsum ad commodo cupidatat do **exercitation** incididunt culpa velit quis. ***Consequat commodo*** reprehenderit duis [irure](#!) esse esse exercitation minim enim Lorem[^1] dolore duis irure. Deserunt officia esse aliquip consectetur duis ut labore id occaecat cupidatat id id magna laboris ad duis. Fugiat cillum dolore veniam nostrud.

*Cupidatat consequat* ommodo ![cat](http://placekitten.com/16/16) non ea cupidatat ![cat](http://placekitten.com/80/80) magna deserunt dolore ipsum velit nulla elit.

[^1]: Footnote example!

# Heading 2 - Code Block

<!--{% contentfor hero %}-->
Nostrud enim ad commodo incididunt cupidatat in ullamco ullamco Lorem cupidatat velit enim et Lorem. Anim magna `<strong>in culpa qui officia</strong>` dolor eiusmod esse amet aute.

```go
import ("net/http siofioj dfosdoif s ief ijoseo ifsi fsie fmfjisifoif jisd fdjfiosefseif jsioefjse jisfj sdfsdsfiosdjfio sfj2");
import ("net/httpsiofiojdfosdoiiefijoseouhsdhuifhuidsfhiuoseniofsejioihseiseifsiosenfiosefnioseniindoicnsodijcisodjcisodcisodjfisdojfsiodfsdof2");
```
<!--{% endcontentfor %}-->

## Heading 3 is a long heading. Aute officia nulla deserunt do deserunt cillum velit magna. Aliquip et adipisicing sit sit fugiat commodo id sunt.

1. Longan
   2. Lychee
   3. Excepteur ad cupidatat do elit laborum amet cillum reprehenderit consequat quis.
    Deserunt officia esse aliquip consectetur duis ut labore laborum commodo aliquip aliquip velit pariatur dolore.
4. Marionberry
5. Melon
    - Cantaloupe
    - Honeydew
    - Watermelon
7. Mulberry

### Heading 4 - List

- Olive
- Orange
  - Blood orange
  - Clementine
- Papaya
- Ut aute ipsum occaecat nisi culpa Lorem id occaecat cupidatat id id magna laboris ad duis. Fugiat cillum dolore veniam nostrud proident sint consectetur eiusmod irure adipisicing.
- Passionfruit

#### Heading 5 - Blockquote

Ad nisi laborum aute cupidatat magna deserunt eu id laboris id. Aliquip nulla cupidatat sint ex Lorem mollit laborum dolor amet est ut esse aute.

> Ipsum et cupidatat mollit exercitation enim duis sunt irure aliqua reprehenderit mollit. Pariatur Lorem pariatur laboris do.
>
> Culpa do elit irure. Eiusmod amet nulla voluptate velit culpa et aliqua ad reprehenderit sit ut.
>
> --- <cite>Myself</cite>

Labore ea magna Lorem consequat aliquip consectetur cillum duis dolore. Et veniam dolor qui incididunt minim amet laboris sit. Dolore ad esse commodo et dolore amet est velit ut nisi ea.

##### Heading 6 - Table

Duis sunt ut pariatur reprehenderit mollit mollit magna dolore in pariatur nulla commodo sit dolor ad fugiat.

<!--{% table large %}-->
| Table Heading 1 | Table Heading 2 | Center align    | Right align     |
| :-------------- | :-------------- | :-------------: | --------------: |
| Item 1          | Item 2          | Item 3          | Item 4          |
| Item 1          | Item 2          | Item 3          | Item 4          |
| Item 1          | Item 2          | Item 3          | Item 4          |
| Item 1          | Item 2          | Item 3          | Item 4          |
| Item 1          | Item 2          | Item 3          | Item 4          |
<!--{% endtable %}-->

Minim id consequat adipisicing cupidatat laborum culpa veniam non consectetur et duis pariatur reprehenderit eu ex consectetur.

# Images

1. {% img image=logo %}
2. {% img image=0001 id='Bones & Clocks' %}
3. {% img src=img.jpg alt='Alt @#~[}{}><>?-+=&^; text' format=thumb %}
4. {% img src=img.jpg format=thumb x=y %}
5. {% img src=img.jpg alt=Image w=50% h=200 %}
6. {% img url src=img.jpg alt=Image w=50% h=auto format=thumb %}

[![Not so big](http://placekitten.com/480/200)](google.com)

# Links

* {% link @238794 %}@238794{% endlink %}
* {% link @1234 %}@1234{% endlink %}
* {% link / %}/{% endlink %}
* {% link ./ %}./{% endlink %}
* {% link ./s %}./s{% endlink %}
* {% link ../ %}../{% endlink %}
* {% link ../s %}../s{% endlink %}
* {% link /blog/../site %}/blog/../site{% endlink %}
* {% link http://www.google.com %}http://www.google.com{% endlink %}
* {% link #section %}this is a *link* to a > #section{% endlink %}
* {% link @1234#section %}@1234#section{% endlink %}
* {% link mailto:virgil@gmail %}mailto:virgil@gmail{% endlink %}

# Video

{% video %}

# Definition List

Image below
Below, image
: Is small
: Is a link

{% contentfor form %}
{% include_relative index_form.partial.html %}
{% endcontentfor %}

{% include_relative grid_tests.html %}
