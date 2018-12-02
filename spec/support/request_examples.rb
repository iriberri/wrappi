shared_examples 'request_examples' do
  let(:params) { {} }
  subject { endpoint.new(params) }
  context 'without params' do
    it do
      expect(subject.response.status).to eq 200
      expect(subject.response.success?).to be true
      expect(subject.response.body).to be_a Hash
    end
  end
  context 'with params' do
    let(:params) { { foo: :baz }}
    it do
      expect(subject.response.status).to eq 200
      expect(subject.response.success?).to be true
      expect(subject.response.body.dig("params", "foo")).to eq 'baz'
    end
  end
end