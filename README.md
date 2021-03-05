# Registro de juegos 🚀

Para realizar este desafío debes haber estudiado previamente todo el material
disponibilizado correspondiente a la unidad.

# Parte 1 📦 

  - A Juan le gustan los juegos de mesa y constantemente está comprando uno nuevo. Por lo
general, prefiere los juegos de tablero competitivos y que puedan desarrollar variadas
estrategias.
Cada vez que compra un juego nuevo, necesita recordar cuáles son las reglas y qué
componentes o piezas tiene.
Como buen amigo, le propones desarrollar un sistema que le permita registrar cada uno de
los juegos que ha comprado.

**Instrucciones**

1. Identifica los modelos y sus relaciones.
2. El sistema almacena las reglas del juego en PDF, además del texto.
3. El sistema almacena una foto de la caja del tablero.
4. El sistema almacena las fotos de las piezas y partes del tablero.
5. Las fotos deben tener thumbnails de 100x100 en escala de grises.
6. Los archivos deben estar almacenados en S3.
7. Todos los archivos deben tener un link de descarga.

Para desarrollar este proyecto se debe instalar `active storage` y ejecutar el *bundle*
```sh
rails active_storage:install
```
También se requieren las siguientes gemas en el Gemfile:
* gem "mini_magick"
* gem 'rmagick'
* gem 'aws-sdk-s3'
* gem 'mutool'
* gem 'image_processing', '~> 1.2'

Para este proyecto el modelo que se usa es `game.rb` con los atributos name y description, este último se usará para el texto de las reglas.
```sh
class CreateGames < ActiveRecord::Migration[6.0]
  def change
    create_table :games do |t|
      t.string :name
      t.text :description

      t.timestamps
    end
  end
end
```

```sh
create_table "games", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  endcreate_table "games", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end
```
En el modelo `game.rb` se agregan los attachment de *cover* (portada), *rule* (reglas en pdf) y *pieces* (piezas del juego y el tablero)
```sh
class Game < ApplicationRecord
    has_one_attached :cover
    has_one_attached :rule
    has_many_attached :pieces
end
```
Se crea un nuevo controlador `games_controller` con los atributos name y description:text
```sh
 rails g controller games name description:text
```
En el controlador `games_controller.rb` se debe agregar los nuevos params *cover*, *rule* y *pieces*. Este último debe ser un arreglo ya que recibirá muchas fotos. Para evitar el N+1 se agrega en el index `with_attached_pieces.all`
```sh
class GamesController < ApplicationController
  before_action :set_game, only: %i[ show edit update destroy ]
  
  def index
    @games = Game.with_attached_pieces.all
  end
    ...
  private
    ...
    def game_params
      params.require(:game).permit(:name, :description, :cover, :rule, pieces: [])
    end
end
```
En la vista `views/games/_form.html.erb` se edita el formulario
```sh
<%= form_with(model: game, local: true) do |form| %>
  <% if game.errors.any? %>
    <div id="error_explanation">
      <h2><%= pluralize(game.errors.count, "error") %> prohibited this game from being saved:</h2>

      <ul>
        <% game.errors.full_messages.each do |message| %>
          <li><%= message %></li>
        <% end %>
      </ul>
    </div>
  <% end %>

  <div class="field">
    <%= form.label :name, 'Nombre del juego' %>
    <%= form.text_field :name %>
  </div>

  <div class="field">
    <%= form.label :cover, 'Portada del juego' %>
    <%= form.file_field :cover %>
  </div>

  <div class="field">
    <%= form.label :description, 'Reglas del juego' %>
    <%= form.text_area :description %>
  </div>

  <div class="field">
    <%= form.label :rule, 'Reglas en PDF' %>
    <%= form.file_field :rule %>
  </div>

  <div class="field">
    <%= form.label :pieces, 'Partes del juego' %>
    <%= form.file_field :pieces, multiple: true %>
  </div>

  <div class="actions">
    <%= form.submit %>
  </div>
<% end %>
```
En la vista `views/games/index.html.erb` se agrega los campos de portada, reglas y piezas del juego, para evitar el error de *attached nil* se agrega un condicional preguntando por el attached `if game.cover.attached?`, como se debe tener los thumbnails de 100x100 en escala de grises se agrega la variante indicando el tamaño y el color `.variant(resize: "100x100", colorspace: "gray")`.
Como requiere que las reglas sean en PDF se debe generar un preview con los mismo datos de la variante de tamaño y color `.preview(resize: "100x100", colorspace: "gray"`.
Por último para agregar link de descarga se agrega `link_to "-->", rails_blob_path(piece, disposition: "attachment")`
```sh
<p id="notice"><%= notice %></p>

<h1>Games</h1>

<table>
  <thead>
    <tr>
      <th>Name</th>
      <th>Cover</th>
      <th>Description</th>
      <th>Reglas PDF</th>
      <th colspan="2">Piezas del juego</th>
      <th colspan="3"></th>
    </tr>
  </thead>

  <tbody>
    <% @games.each do |game| %>
      <tr>
        <td><%= game.name %></td>
        <td>
          <% if game.cover.attached?%>
            <td><%= image_tag game.cover.variant(resize: "100x100", colorspace: "gray") %><%= link_to "-->", rails_blob_path(game.cover, disposition: "attachment") %></td>
          <% end %>        
        <td><%= game.description %></td>
        <td>
          <% if game.rule.attached?%>
            <%= image_tag game.rule.preview(resize: "100x100", colorspace: "gray")%><%= link_to "-->", rails_blob_path(game.rule, disposition: "attachment") %>
          <% end %>
        </td>
        <td>
          <ul>
            <% game.pieces.each do |piece| %>
              <% if piece.variable? %>
                <li><%= image_tag piece.variant(resize: "100x100", colorspace: "gray") %> <%= link_to "-->", rails_blob_path(piece, disposition: "attachment") %></li>
              <% elsif piece.previewable? %>
                <li><%= image_tag piece.preview(resize: "100x100", colorspace: "gray") %> <%= link_to "-->", rails_blob_path(piece, disposition: "attachment") %></li>
              <% end %>
            <% end %>
          </ul>
        </td>

        <td><%= link_to 'Show', game %></td>
        <td><%= link_to 'Edit', edit_game_path(game) %></td>
        <td><%= link_to 'Destroy', game, method: :delete, data: { confirm: 'Are you sure?' } %></td>
      </tr>
    <% end %>
  </tbody>
</table>

<br>

<%= link_to 'New Game', new_game_path %>

```
Para que los oarchivos esten almacenados en S3 se configura el `active_storage.service` en `config/enviroments/development.rb` y asociarlo con *amazon*
```sh
config.active_storage.service = :amazon
```
Por último en `config/storage.yml` se habilita toda la sección de amazon y se agregan los datos creados previamente en Amazon Web Services. Los datos del *access_key_id* y *secret_access_key* son creados con una variable de entorno.
```sh
amazon:
  service: S3
  access_key_id: <% ENV['AWS_ACCESS_KEY_ID'] %>
  secret_access_key: <% ENV['AWS_SECRET_ACCESS_KEY'] %>
  region: us-east-1
  bucket: boardgamebucket
```
# Construido con 🛠️

* Ruby [2.6.6] - Lenguaje de programación usado
* Rails [6.0.3.4]  - Framework web usado

## Autores ✒️

* **Lina Sofía Vallejo Betancourth** - *Trabajo Inicial y documentación* - [linav92](https://github.com/linav92)


## Licencia 📄

Este proyecto es un software libre. 
