require 'rails_helper'

RSpec.describe Source, type: :model do
  describe '#process_text' do
    it 'processes opml data as expected' do
      data = File.open(Rails.root.join('spec', 'fixtures', 'source_example.opml')).read
      source = Source.create!(
        text: data,
        file_type: 'opml',
        show: Show.create!(
          name: 'Test Show'
        )
      )

      source.process_text!

      by_topics = source.show.notes.group_by(&:topic)

      expect(by_topics.keys).to eq [
                                     'PR',
                                     'Charlottesville',
                                     'CLIPS AND DOCS',
                                     'F-Russia',
                                     'JCD Clips',
                                     'Shut Up Slave!'
                                   ]

      charlottesville = by_topics['Charlottesville']
      expect(charlottesville.count).to eq 2

      note1 = charlottesville[0]
      expect(note1.text).to eq 'Charlottesville is just plain crazy.'

      expected = {
        Charlottesville:[
          {
            title: 'From SpookyR',
            text: 'Charlottesville is just plain crazy.',
            url_entries: []
          },
          {
            title: 'White Nationalists March on University of Virginia - The New York Times',
            text: [
              '<a href="https://www.nytimes.com/2017/08/11/us/white-nationalists-rally-charlottesville-virginia.html?smid=fb-share">Link to Article</a>',
              '<a href="http://adam.curry.com/art/1502551602_zrtBDCVz.html">Archived Version</a>',
              'Sat, 12 Aug 2017 15:26',
              'Photo White nationalists rallied at a statue of...',
              "Thousands of people '-- many from out of town '-- are..."
                   ].join("\n"),
            url_entries: [
              {
                text: 'Link to Article',
                url:   'https://www.nytimes.com/2017/08/11/us/white-nationalists-rally-charlottesville-virginia.html?smid=fb-share',
              },
              {
                text: 'Archived Version',
                url:   'http://adam.curry.com/art/1502551602_zrtBDCVz.html'
              }
                   ]
          }
                        ]
      }

      actual = by_topics.slice('Charlottesville').map do |topic, notes|
        [topic, notes.map do |note|
          note.slice(:title, :text).merge(
            url_entries: note.url_entries.map { |e| e.slice(:text, :url) },
          )
        end]
      end.to_h

      expect(actual.deep_symbolize_keys).to eq expected.deep_symbolize_keys
    end

    context 'with show 1250' do
      let(:data) { File.read(Rails.root.join('spec', 'fixtures', 'NoAgenda1250.opml')) }
      let(:source) { Source.create!(text: data, file_type: 'opml', show: Show.create!(name: 'Test Show')) }

      before do
        source.process_text!
      end

      it 'finds all the clips' do
        clips = source.show.notes.where(topic: 'All Clips')

        expect(clips.count).to eq 52
      end

      it 'parses clips correctly' do
        clips = source.show.notes.where(topic: 'All Clips')
        clip = clips.find { |c| c.title == 'Last show definition of racism.mp3' }
        expect(clip.text).to include 'http://adam.curry.com/enc/1591906237.485_lastshowdefinitionofracism.mp3'

        expect(clips.map(&:text)).to all match /\.(mp3|m4a)/
      end

      it 'finds all the shownotes' do
        notes = source.show.notes.where.not(topic: 'All Clips')

        expect(notes.count).to eq 164
      end

      it 'parses a normal, nested shownote correctly' do
        notes = source.show.notes.where.not(topic: 'All Clips')

        note = notes.where(topic: 'BLM', title: 'Repetition compulsion - Wikipedia').first!
        expect(note.text).to include 'Repetition compulsion is a psychological phenomenon'
        expect(note.text).to include 'can also be used to cover the repetition of behaviour'
      end

      it 'deals with untitled, unnested notes correctly' do
        notes = source.show.notes.where.not(topic: 'All Clips')
        # This is a weird one. Not sure what to do with it.
        # I have asserted that it should be present, but maybe we should just skip them.
        # Or maybe we should join these together until we find the next nested note in the group.
        note = notes.where(topic: 'TODAY', title: 'Katie Williams Apology - White people memo').first!
        expect(note.text).to eq "<b><i>Katie Williams Apology - White people memo</i></b>"
      end
    end
  end
end
