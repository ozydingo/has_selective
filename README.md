# selfish_associations
## Not ready yet. Do not use.

### Create ActiveRecord-like associations with self-awareness

SelfishAssociations are very similar to ActiveRecord Associations, with one key [added feature](#key-feature).

ActiveRecord allows you to scope associations, and has some limited support for passing in the self instance to that scope:

```
class Video
  has_one :native_transcript, ->(vid){ where language_id: vid.language_id }, class_name: "Transcript"
end

video = Video.first
# => #<Video id: 1, language_id: 1>
video.native_transcript
# => #<Transcript id: 1, video_id: 1, language_id: 1>
```

However because `language_id` is written as an instance method of `vid`, this cannot be used for a `joins`:

```
Video.joins(:native_transcript)
# NoMethodError: undefined method `langauge_id' for #<ActiveRecord::Associations::JoinDependency::JoinAssociation:0x007f7f623dc640>
```

SelfishAssociations covers this gap by interpreting the scope correctly for both instance and class-level queries. Thus, you can have your instance, and join it, too! For this version, we are keeping the syntax entirely separate from the ActiveRecord methods to not tread on too many toes. This also means that combining selfish associaitons with reglar associations is difficult and not yet supported. Pull requests welcome!

<a name="key-feature" />

```
class Video
  has_one_selfish :native_transcript, ->(vid){ where language_id: vid.language_id }, class_name: "Transcript"
end

video = Video.first
# => #<Video id: 1, language_id: 1>
video.native_transcript
# => #<Transcript, id: 1, video_id: 1, language_id: 1>
Video.joins(:native_transcript).to_sql
# => "SELECT videos.* FROM videos INNER JOIN transcripts ON transcripts.video_id = videos.id AND transcripts.language_id = videos.language_id"
```

You can specify (ActiveRecord) associations of the self model inside the scope too, and SelfishAssociations will generate the correct intermediate joins:

```
class Video
  belongs_to :language
  has_one_selfish :native_transcript, ->(vid){ where language_name: vid.language.name }, class_name: "Transcript"
end

Video.joins(:native_transcript).to_sql
# => "SELECT videos.* FROM videos INNER JOIN languages ON languages.id = videos.language_id INNER JOIN transcripts ON transcripts.video_id = videos.id AND transcripts.language_name = languages.name"
Video.first.native_transcript
# => <Transcript, id: 1, video_id: 1, language_name: "English">
```

This is safe to missing associations; you do not have to litter your associations with `try!`s:

```
video = Video.first
# => <#Video id: 1, language_id: nil>
video.language
# => nil
video.native_transcript
# => nil
```

Because of this approach to associations, you can in fact define an association that does NOT require a foreign key / belongs_to inverse:

```
class Video
  has_one_selfish :native_transcript, ->(vid){ where external_id: vid.external_id, language_id: vid.language_id }, class_name: "Transcript", foreign_key: false
end

video = Video.first
# => #<Video id: 1, language_id: 1, external_id: "xyz">
video.native_transcript
# => #<Transcript, id: 1, video_id: nil, language_id: 1, external_id: "xyz">
Video.joins(:native_transcript).to_sql
# => "SELECT videos.* FROM videos INNER JOIN transcripts ON transcripts.external_id = videos.external_id AND transcripts.language_id = videos.language_id"
```

Of course, if you're doing this, ask yourself if that's really the best setup and why you don't want to just link the Transcript to the Video directly after create or after updating the external_id. Most of the time, this is what you should do: it's more expected, it's indexed, it's better supported that this stupid little gem. But the power is yours.

More details spec for association definition to follow.
